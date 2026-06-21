/**
 * AI 对话数据模型
 */

/** 对话角色 */
export enum ChatRole {
  USER = 'user',
  ASSISTANT = 'assistant',
  SYSTEM = 'system'
}

/** 单条聊天消息 */
export interface ChatMessage {
  /** 消息唯一ID */
  id: string;
  /** 发送角色 */
  role: ChatRole;
  /** 消息正文 */
  content: string;
  /** 发送时间戳 */
  timestamp: number;
  /** 是否正在接收中（流式响应） */
  isStreaming: boolean;
}

/** 预设Prompt类型 */
export enum PromptType {
  /** 周度分析 */
  WEEKLY_ANALYSIS = 'weekly_analysis',
  /** 进展回顾 */
  PROGRESS_REVIEW = 'progress_review',
  /** 生成计划 */
  GENERATE_PLAN = 'generate_plan',
  /** 弱点识别 */
  WEAKNESS_ANALYSIS = 'weakness_analysis',
  /** 恢复建议 */
  RECOVERY_ADVICE = 'recovery_advice'
}

/** 预设Prompt定义 */
export interface PromptTemplate {
  type: PromptType;
  title: string;
  icon: string;
  systemPrompt: string;
}

/** AI对话会话 */
export interface AiConversation {
  /** 会话ID */
  id: string;
  /** 消息列表 */
  messages: ChatMessage[];
  /** 创建时间 */
  createdAt: number;
  /** 最后活动时间 */
  lastActivityAt: number;
}

/** DeepSeek API 配置 */
export interface DeepSeekConfig {
  apiKey: string;
  model: string;
  temperature: number;
  maxTokens: number;
}

export const DEFAULT_DEEPSEEK_CONFIG: DeepSeekConfig = {
  apiKey: '',
  model: 'deepseek-chat',
  temperature: 0.7,
  maxTokens: 4096
};

/** 预设Prompt列表 */
export const PROMPT_TEMPLATES: PromptTemplate[] = [
  {
    type: PromptType.WEEKLY_ANALYSIS,
    title: '周度分析',
    icon: '📊',
    systemPrompt: '请分析我最近一周的训练数据，包括训练频率、强度变化、动作表现等，给出具体的分析和建议。'
  },
  {
    type: PromptType.PROGRESS_REVIEW,
    title: '进展回顾',
    icon: '📈',
    systemPrompt: '请回顾我近期的训练进展，重点关注三大项（深蹲、卧推、硬拉）的1RM变化趋势，指出进步和瓶颈。'
  },
  {
    type: PromptType.GENERATE_PLAN,
    title: '生成计划',
    icon: '📋',
    systemPrompt: '请根据我的历史训练数据和当前水平，生成下一周的详细训练计划，包括动作选择、组数、次数和重量建议。'
  },
  {
    type: PromptType.WEAKNESS_ANALYSIS,
    title: '弱点识别',
    icon: '🔍',
    systemPrompt: '请分析我的训练数据，识别薄弱环节和需要加强的动作/肌群，给出针对性的改进建议。'
  },
  {
    type: PromptType.RECOVERY_ADVICE,
    title: '恢复建议',
    icon: '💪',
    systemPrompt: '请根据我的训练负荷和频率，评估我的恢复状态，给出休息、营养和恢复训练的建议。'
  }
];

/** 预设训练计划 */
export interface TrainingPlan {
  id: string;
  name: string;
  description: string;
  daysPerWeek: number;
  difficulty: '入门' | '中级' | '高级';
  prompt: string;
}

/** 预设训练计划库 */
export const TRAINING_PLANS: TrainingPlan[] = [
  {
    id: 'ppl',
    name: '推/拉/腿 (PPL)',
    description: '经典的 Push/Pull/Legs 三分化，每周6天',
    daysPerWeek: 6,
    difficulty: '中级',
    prompt: '请根据我的训练数据生成一份推拉腿(PPL)三分化训练计划，每周6天，包含具体的动作、组数、次数范围和建议重量。'
  },
  {
    id: 'upper_lower',
    name: '上下肢分化',
    description: '上肢/下肢 四分化，每周4天',
    daysPerWeek: 4,
    difficulty: '中级',
    prompt: '请根据我的训练数据生成一份上下肢分化训练计划，每周4天，包含具体的动作、组数、次数范围和建议重量。'
  },
  {
    id: 'stronglifts',
    name: 'StrongLifts 5x5',
    description: '经典的力量举入门，每周3天，专注三大项',
    daysPerWeek: 3,
    difficulty: '入门',
    prompt: '请根据我的训练数据生成一份StrongLifts 5x5计划，每周3天，包含深蹲、卧推、硬拉的具体安排。'
  },
  {
    id: 'phul',
    name: 'PHUL 力量/增肌',
    description: '兼顾力量与肌肉量，每周4天',
    daysPerWeek: 4,
    difficulty: '中级',
    prompt: '请根据我的训练数据生成一份PHUL计划(Power Hypertrophy Upper Lower)，每周4天。'
  },
  {
    id: 'fullbody',
    name: '全身训练',
    description: '每周3天，适合新手或时间有限',
    daysPerWeek: 3,
    difficulty: '入门',
    prompt: '请根据我的训练数据生成一份全身训练计划，每周3次，包含主要复合动作。'
  }
];
