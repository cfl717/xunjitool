import http from '@ohos.net.http';
import { DeepSeekConfig } from '../models/AiConversation';
import { DEEPSEEK_API } from '../utils/Constants';

interface ApiMessage { role: string; content: string; }

export type { ApiMessage };

export function buildSystemPrompt(trainingContext: string): string {
  return '你是专业的健身教练助手，帮助用户分析训练数据并提供建议。\n当前用户的训练数据概况：\n' + trainingContext + '\n请根据以上数据给出专业的分析和建议。回答要具体、有数据支撑、可操作。使用中文。';
}

export async function callDeepSeek(config: DeepSeekConfig, messages: ApiMessage[]): Promise<string> {
  if (!config.apiKey) { throw new Error('请先设置 DeepSeek API Key'); }
  const httpRequest = http.createHttp();
  try {
    const response = await httpRequest.request(DEEPSEEK_API.BASE_URL + DEEPSEEK_API.CHAT_ENDPOINT, {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + config.apiKey },
      extraData: JSON.stringify({
        model: config.model || DEEPSEEK_API.MODEL, messages: messages,
        temperature: config.temperature ?? 0.7, max_tokens: config.maxTokens ?? 4096, stream: false
      }),
      connectTimeout: DEEPSEEK_API.TIMEOUT_MS, readTimeout: DEEPSEEK_API.TIMEOUT_MS
    });
    if (response.responseCode !== 200) { throw new Error('API请求失败: ' + response.responseCode); }
    const data = response.result as Record<string, Object>;
    // Check for API error response (no 'choices' field)
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
    return (msg['content'] as string) || '';
  } finally {
    httpRequest.destroy();
  }
}
