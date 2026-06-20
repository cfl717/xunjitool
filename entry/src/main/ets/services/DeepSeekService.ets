/**
 * DeepSeek AI 服务
 * 流式对话API调用
 */
import util from '@ohos.util';

import { DeepSeekConfig, ChatMessage, ChatRole } from '../models/AiConversation';
import { DEEPSEEK_API } from '../utils/Constants';

/** DeepSeek API 响应块（流式） */
interface StreamChunk {
  choices: {
    delta: { content?: string };
    finish_reason: string | null;
  }[];
}

/** 构建系统Prompt（注入训练数据） */
export function buildSystemPrompt(trainingContext: string): string {
  return `你是专业的健身教练助手，帮助用户分析训练数据并提供建议。

当前用户的训练数据概况：
${trainingContext}

请根据以上数据给出专业的分析和建议。回答要具体、有数据支撑、可操作。使用中文。`;
}

/** 构建训练上下文摘要 */
export function buildTrainingContext(summary: {
  totalSessions: number;
  totalDays: number;
  recentSessions: { date: string; name: string; exercises: string }[];
  bigThreePRs: { name: string; oneRm: number }[];
}): string {
  let context = `总训练次数: ${summary.totalSessions}，总训练天数: ${summary.totalDays}\n\n`;

  if (summary.bigThreePRs.length > 0) {
    context += '三大项1RM:\n';
    for (const pr of summary.bigThreePRs) {
      context += `- ${pr.name}: ${pr.oneRm}kg\n`;
    }
    context += '\n';
  }

  context += '最近训练:\n';
  for (const s of summary.recentSessions.slice(0, 10)) {
    context += `- ${s.date} ${s.name}: ${s.exercises}\n`;
  }

  return context;
}

/**
 * 调用 DeepSeek API（非流式）
 */
export async function callDeepSeek(
  config: DeepSeekConfig,
  messages: { role: string; content: string }[]
): Promise<string> {
  if (!config.apiKey) {
    throw new Error('请先设置 DeepSeek API Key');
  }

  const url = `${DEEPSEEK_API.BASE_URL}${DEEPSEEK_API.CHAT_ENDPOINT}`;

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${config.apiKey}`
    },
    body: JSON.stringify({
      model: config.model || DEEPSEEK_API.MODEL,
      messages: messages,
      temperature: config.temperature ?? 0.7,
      max_tokens: config.maxTokens ?? 4096,
      stream: false
    })
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`API请求失败 (${response.status}): ${errText}`);
  }

  const data = await response.json();
  return data.choices?.[0]?.message?.content || '';
}

/**
 * 调用 DeepSeek API（流式）
 * 返回 AsyncGenerator，每块 yield 增量文本
 */
export async function* callDeepSeekStream(
  config: DeepSeekConfig,
  messages: { role: string; content: string }[]
): AsyncGenerator<string> {
  if (!config.apiKey) {
    throw new Error('请先设置 DeepSeek API Key');
  }

  const url = `${DEEPSEEK_API.BASE_URL}${DEEPSEEK_API.CHAT_ENDPOINT}`;

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${config.apiKey}`
    },
    body: JSON.stringify({
      model: config.model || DEEPSEEK_API.MODEL,
      messages: messages,
      temperature: config.temperature ?? 0.7,
      max_tokens: config.maxTokens ?? 4096,
      stream: true
    })
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`API请求失败 (${response.status}): ${errText}`);
  }

  // 解析流式响应
  const reader = response.body?.getReader();
  if (!reader) {
    throw new Error('无法获取响应流');
  }

  const decoder = util.TextDecoder.create('utf-8');
  let buffer = '';

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buffer += decoder.decodeToString(value);
    const lines = buffer.split('\n');
    buffer = lines.pop() || '';

    for (const line of lines) {
      if (line.startsWith('data: ')) {
        const data = line.substring(6).trim();
        if (data === '[DONE]') return;
        try {
          const chunk: StreamChunk = JSON.parse(data);
          const content = chunk.choices?.[0]?.delta?.content || '';
          if (content) {
            yield content;
          }
        } catch {
          // 跳过解析失败的块
        }
      }
    }
  }

  // 处理缓冲区剩余内容
  if (buffer.startsWith('data: ')) {
    const data = buffer.substring(6).trim();
    if (data !== '[DONE]') {
      try {
        const chunk: StreamChunk = JSON.parse(data);
        const content = chunk.choices?.[0]?.delta?.content || '';
        if (content) {
          yield content;
        }
      } catch {
        // 忽略
      }
    }
  }
}
