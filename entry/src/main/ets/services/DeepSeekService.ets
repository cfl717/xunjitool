import http from '@ohos.net.http';
import { DeepSeekConfig } from '../models/AiConversation';
import { DEEPSEEK_API, DEEPSEEK_MODELS } from '../utils/Constants';

interface ApiMessage { role: string; content: string; }

interface ApiResult {
  content: string;
  reasoningContent?: string;
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

export async function callDeepSeek(config: DeepSeekConfig, messages: ApiMessage[]): Promise<ApiResult> {
  if (!config.apiKey) { throw new Error('请先设置 DeepSeek API Key'); }
  const httpRequest = http.createHttp();
  const isReasoning = isReasoningModel(config);

  try {
    // 构造请求体
    const modelName: string = config.model || DEEPSEEK_API.MODEL;
    const reqBody: Record<string, Object> = {};
    reqBody['model'] = modelName;
    reqBody['messages'] = messages;
    reqBody['max_tokens'] = config.maxTokens ?? 4096;
    reqBody['stream'] = false;

    // reasoning 模型不支持 temperature 但支持 reasoning_effort
    if (isReasoning) {
      reqBody['reasoning_effort'] = 'high';
    } else {
      reqBody['temperature'] = config.temperature ?? 0.7;
    }

    const response = await httpRequest.request(DEEPSEEK_API.BASE_URL + DEEPSEEK_API.CHAT_ENDPOINT, {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + config.apiKey },
      extraData: JSON.stringify(reqBody),
      connectTimeout: DEEPSEEK_API.TIMEOUT_MS,
      readTimeout: DEEPSEEK_API.TIMEOUT_MS
    });
    if (response.responseCode !== 200) { throw new Error('API请求失败: ' + response.responseCode); }
    let data: Record<string, Object>;
    if (typeof response.result === 'string') {
      data = JSON.parse(response.result) as Record<string, Object>;
    } else {
      data = response.result as Record<string, Object>;
    }
    const respErr = data['error'] as Record<string, Object> | undefined;
    if (respErr) { throw new Error((respErr['message'] as string) || 'API返回错误'); }
    const choices = data['choices'] as Record<string, Object>[] | undefined;
    if (!choices || choices.length === 0) { throw new Error('API返回数据异常'); }
    const msg = choices[0]['message'] as Record<string, Object> | undefined;
    if (!msg) { throw new Error('API返回消息格式异常'); }
    const result: ApiResult = {
      content: (msg['content'] as string) || ''
    };
    if (isReasoning) {
      const rc = msg['reasoning_content'] as string | undefined;
      if (rc) result.reasoningContent = rc;
    }
    return result;
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
  const result = await callDeepSeek(config, messages);
  if (result.content) onChunk(result.content);
  if (result.reasoningContent && onReasoning) onReasoning(result.reasoningContent);
  return result;
}
