import http from '@ohos.net.http';
import util from '@ohos.util';
import { DeepSeekConfig } from '../models/AiConversation';
import { DEEPSEEK_API, DEEPSEEK_MODELS } from '../utils/Constants';

interface ApiMessage { role: string; content: string; }

interface ApiResult {
  content: string;
  reasoningContent?: string;
}

interface SseParseResult {
  contentDelta: string;
  reasoningDelta: string;
  done: boolean;
  errorMsg: string;
}

export type { ApiMessage, ApiResult };

function isReasoningModel(config: DeepSeekConfig): boolean {
  for (const m of DEEPSEEK_MODELS) {
    if (m.name === config.model && m.supportsReasoning) return true;
  }
  return false;
}

export function buildSystemPrompt(trainingContext: string): string {
  return '你是专业的健身教练助手，帮助用户分析训练数据并提供建议。\n当前用户的训练数据概况：\n' + trainingContext + '\n请根据以上数据给出专业的分析和建议。回答要具体、有数据支撑、可操作。使用中文。';
}

function buildRequestBody(config: DeepSeekConfig, messages: ApiMessage[], stream: boolean): Record<string, Object> {
  const modelName: string = config.model || DEEPSEEK_API.MODEL;
  const isReasoning = isReasoningModel(config);
  const reqBody: Record<string, Object> = {};
  reqBody['model'] = modelName;
  reqBody['messages'] = messages;
  reqBody['max_tokens'] = config.maxTokens ?? 4096;
  reqBody['stream'] = stream;
  if (isReasoning) {
    reqBody['reasoning_effort'] = 'high';
  } else {
    reqBody['temperature'] = config.temperature ?? 0.7;
  }
  return reqBody;
}

function parseSseLine(line: string): SseParseResult | null {
  const trimmed = line.trim();
  if (trimmed.length === 0 || !trimmed.startsWith('data:')) {
    return null;
  }
  const payload = trimmed.startsWith('data: ') ? trimmed.substring(6) : trimmed.substring(5);
  const data = payload.trim();
  if (data === '[DONE]') {
    const done: SseParseResult = { contentDelta: '', reasoningDelta: '', done: true, errorMsg: '' };
    return done;
  }
  try {
    const json = JSON.parse(data) as Record<string, Object>;
    const respErr = json['error'] as Record<string, Object> | undefined;
    if (respErr) {
      const err: SseParseResult = {
        contentDelta: '', reasoningDelta: '', done: true,
        errorMsg: (respErr['message'] as string) || 'API返回错误'
      };
      return err;
    }
    const choices = json['choices'] as Record<string, Object>[] | undefined;
    if (!choices || choices.length === 0) {
      return null;
    }
    const delta = choices[0]['delta'] as Record<string, Object> | undefined;
    if (!delta) {
      return null;
    }
    const result: SseParseResult = {
      contentDelta: (delta['content'] as string) || '',
      reasoningDelta: (delta['reasoning_content'] as string) || '',
      done: false,
      errorMsg: ''
    };
    return result;
  } catch (e) {
    return null;
  }
}

function drainSseBuffer(buffer: string): SseDrainResult {
  const results: SseParseResult[] = [];
  let remain = buffer;
  while (true) {
    const nl = remain.indexOf('\n');
    if (nl < 0) {
      break;
    }
    const line = remain.substring(0, nl);
    remain = remain.substring(nl + 1);
    const parsed = parseSseLine(line);
    if (parsed) {
      results.push(parsed);
    }
  }
  const out: SseDrainResult = { results: results, remainder: remain };
  return out;
}

interface SseDrainResult {
  results: SseParseResult[];
  remainder: string;
}

export async function callDeepSeek(config: DeepSeekConfig, messages: ApiMessage[]): Promise<ApiResult> {
  if (!config.apiKey) { throw new Error('请先设置 DeepSeek API Key'); }
  const startTime = Date.now();
  console.info('[DS] === callDeepSeek start === model=' + (config.model || 'default') + ', messages=' + messages.length);

  const httpRequest = http.createHttp();

  try {
    const reqBody = buildRequestBody(config, messages, false);
    const url = DEEPSEEK_API.BASE_URL + DEEPSEEK_API.CHAT_ENDPOINT;

    const response = await httpRequest.request(url, {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + config.apiKey },
      extraData: JSON.stringify(reqBody),
      connectTimeout: DEEPSEEK_API.TIMEOUT_MS,
      readTimeout: DEEPSEEK_API.TIMEOUT_MS
    });

    console.info('[DS] response received code=' + response.responseCode + ' elapsed=' + (Date.now() - startTime) + 'ms');

    if (response.responseCode !== 200) {
      const body = typeof response.result === 'string' ? response.result.substring(0, 200) : 'non-string';
      console.error('[DS] http error code=' + response.responseCode + ' body=' + body);
      throw new Error('API请求失败: ' + response.responseCode);
    }

    let data: Record<string, Object>;
    if (typeof response.result === 'string') {
      data = JSON.parse(response.result) as Record<string, Object>;
    } else {
      data = response.result as Record<string, Object>;
    }

    const respErr = data['error'] as Record<string, Object> | undefined;
    if (respErr) {
      throw new Error((respErr['message'] as string) || 'API返回错误');
    }

    const choices = data['choices'] as Record<string, Object>[] | undefined;
    if (!choices || choices.length === 0) {
      throw new Error('API返回数据异常');
    }

    const msg = choices[0]['message'] as Record<string, Object> | undefined;
    if (!msg) {
      throw new Error('API返回消息格式异常');
    }

    const content = (msg['content'] as string) || '';
    const result: ApiResult = { content: content };
    if (isReasoningModel(config)) {
      const rc = msg['reasoning_content'] as string | undefined;
      if (rc) {
        result.reasoningContent = rc;
      }
    }
    return result;
  } catch (err) {
    console.error('[DS] callDeepSeek FAILED: ' + JSON.stringify(err));
    if (err instanceof Error) throw err;
    throw new Error(String(err));
  } finally {
    httpRequest.destroy();
  }
}

export async function callDeepSeekStream(
  config: DeepSeekConfig,
  messages: ApiMessage[],
  onChunk: (text: string) => void,
  onReasoning?: (text: string) => void
): Promise<ApiResult> {
  try {
    const result = await callDeepSeekStreamInternal(config, messages, onChunk, onReasoning);
    if (result.content.length === 0 && (!result.reasoningContent || result.reasoningContent.length === 0)) {
      console.warn('[DS] stream empty, fallback to non-stream');
      return await callDeepSeekWithCallbacks(config, messages, onChunk, onReasoning);
    }
    return result;
  } catch (err) {
    console.warn('[DS] stream failed, fallback to non-stream: ' + JSON.stringify(err));
    return await callDeepSeekWithCallbacks(config, messages, onChunk, onReasoning);
  }
}

async function delayMs(ms: number): Promise<void> {
  return new Promise<void>((resolve: () => void) => {
    setTimeout(resolve, ms);
  });
}

async function emitSimulatedStream(
  result: ApiResult,
  onChunk: (text: string) => void,
  onReasoning?: (text: string) => void
): Promise<ApiResult> {
  if (result.reasoningContent && result.reasoningContent.length > 0 && onReasoning) {
    const rc = result.reasoningContent;
    let i = 0;
    while (i < rc.length) {
      const end = i + 16 > rc.length ? rc.length : i + 16;
      onReasoning(rc.substring(i, end));
      i = end;
      await delayMs(12);
    }
  }
  if (result.content.length > 0) {
    const text = result.content;
    let i = 0;
    while (i < text.length) {
      const end = i + 24 > text.length ? text.length : i + 24;
      onChunk(text.substring(i, end));
      i = end;
      await delayMs(30);
    }
  }
  return result;
}

async function callDeepSeekWithCallbacks(
  config: DeepSeekConfig,
  messages: ApiMessage[],
  onChunk: (text: string) => void,
  onReasoning?: (text: string) => void
): Promise<ApiResult> {
  const result = await callDeepSeek(config, messages);
  return await emitSimulatedStream(result, onChunk, onReasoning);
}

function callDeepSeekStreamInternal(
  config: DeepSeekConfig,
  messages: ApiMessage[],
  onChunk: (text: string) => void,
  onReasoning?: (text: string) => void
): Promise<ApiResult> {
  if (!config.apiKey) { throw new Error('请先设置 DeepSeek API Key'); }
  const startTime = Date.now();
  console.info('[DS] === callDeepSeekStream start === model=' + (config.model || 'default'));

  const httpRequest = http.createHttp();
  const decoder = util.TextDecoder.create('utf-8');
  const streamOn: util.DecodeToStringOptions = { stream: true };
  const streamOff: util.DecodeToStringOptions = { stream: false };
  let sseBuffer = '';
  let fullContent = '';
  let fullReasoning = '';
  let responseCode = 0;
  let streamError = '';
  let settled = false;
  let receivedAnyData = false;

  const finish = (resolve: (v: ApiResult) => void, reject: (e: Error) => void): void => {
    if (settled) return;
    settled = true;
    httpRequest.off('dataReceive');
    httpRequest.off('dataEnd');
    httpRequest.off('headersReceive');
    httpRequest.destroy();
    if (streamError.length > 0) {
      reject(new Error(streamError));
      return;
    }
    if (responseCode !== 0 && responseCode !== 200) {
      reject(new Error('API请求失败: ' + responseCode));
      return;
    }
    const result: ApiResult = { content: fullContent };
    if (fullReasoning.length > 0) {
      result.reasoningContent = fullReasoning;
    }
    console.info('[DS] stream done content_len=' + fullContent.length + ' elapsed=' + (Date.now() - startTime) + 'ms');
    resolve(result);
  };

  const processText = (text: string): void => {
    const normalized = text.replace(/\r\n/g, '\n').replace(/\r/g, '\n');
    sseBuffer += normalized;
    const drained = drainSseBuffer(sseBuffer);
    sseBuffer = drained.remainder;
    for (let i = 0; i < drained.results.length; i++) {
      const ev = drained.results[i];
      if (ev.errorMsg.length > 0) {
        streamError = ev.errorMsg;
        return;
      }
      if (ev.contentDelta.length > 0) {
        fullContent += ev.contentDelta;
        onChunk(ev.contentDelta);
      }
      if (ev.reasoningDelta.length > 0) {
        fullReasoning += ev.reasoningDelta;
        if (onReasoning) {
          onReasoning(ev.reasoningDelta);
        }
      }
    }
  };

  return new Promise<ApiResult>((resolve, reject) => {
    httpRequest.on('headersReceive', (header: Object) => {
      const h = header as Record<string, Object>;
      responseCode = (h['responseCode'] as number) || 0;
      console.info('[DS] stream responseCode=' + responseCode);
    });

    httpRequest.on('dataReceive', (data: ArrayBuffer) => {
      receivedAnyData = true;
      const text = decoder.decodeToString(new Uint8Array(data), streamOn);
      processText(text);
    });

    httpRequest.on('dataEnd', () => {
      const tail = decoder.decodeToString(new Uint8Array(0), streamOff);
      if (tail.length > 0) {
        processText(tail);
      }
      if (sseBuffer.length > 0) {
        processText('\n');
      }
      finish(resolve, reject);
    });

    const reqBody = buildRequestBody(config, messages, true);
    const url = DEEPSEEK_API.BASE_URL + DEEPSEEK_API.CHAT_ENDPOINT;

    httpRequest.requestInStream(url, {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + config.apiKey },
      extraData: JSON.stringify(reqBody),
      connectTimeout: DEEPSEEK_API.TIMEOUT_MS,
      readTimeout: DEEPSEEK_API.STREAM_TIMEOUT_MS
    }, (err: BusinessError, code: number) => {
      if (err) {
        console.error('[DS] requestInStream error: ' + JSON.stringify(err));
        if (!settled) {
          settled = true;
          httpRequest.destroy();
          reject(new Error('网络请求失败'));
        }
        return;
      }
      console.info('[DS] requestInStream callback code=' + code);
      if (code !== 200 && code !== 0) {
        console.error('[DS] requestInStream bad code=' + code);
        streamError = 'API请求失败: ' + code;
      }
    });

    setTimeout(() => {
      if (!settled && !receivedAnyData) {
        console.warn('[DS] stream timeout after ' + DEEPSEEK_API.STREAM_TIMEOUT_MS + 'ms');
        streamError = streamError.length > 0 ? streamError : '流式响应超时';
        finish(resolve, reject);
      }
    }, DEEPSEEK_API.STREAM_TIMEOUT_MS);
  });
}
