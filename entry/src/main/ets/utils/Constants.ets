/**
 * 全局常量
 */

/** 存储键名 */
export const STORAGE_KEYS = {
  /** 解析后的训练数据缓存 */
  TRAINING_DATA: 'training_data',
  /** 数据最后更新时间 */
  LAST_UPDATE: 'last_update',
  /** DeepSeek API Key */
  DEEPSEEK_API_KEY: 'deepseek_api_key',
  /** DeepSeek API 配置 */
  DEEPSEEK_CONFIG: 'deepseek_config',
  /** 用户偏好设置 */
  USER_PREFERENCES: 'user_preferences'
} as const;

/** DeepSeek API */
export const DEEPSEEK_API = {
  BASE_URL: 'https://api.deepseek.com',
  CHAT_ENDPOINT: '/chat/completions',
  MODEL: 'deepseek-chat',
  TIMEOUT_MS: 60000
} as const;

/** 热力图颜色等级 */
export const HEATMAP_COLORS: string[] = [
  '#FF232340', // 0 训练日
  '#FF1A3A4A', // 1
  '#FF145A32', // 2
  '#FF1B7A3A', // 3
  '#FF2E9E4A'  // 4+
];

/** 应用栏标题 */
export const TAB_TITLES = {
  DASHBOARD: '首页',
  LOG: '训练',
  PROGRESS: '进展',
  AI_COACH: 'AI教练'
} as const;
