interface StorageKeys { TRAINING_DATA: string; LAST_UPDATE: string; DEEPSEEK_API_KEY: string; DEEPSEEK_CONFIG: string; USER_PREFERENCES: string; XUNJI_TOKEN: string; }
interface DeepSeekApi { BASE_URL: string; CHAT_ENDPOINT: string; MODEL: string; TIMEOUT_MS: number; }
interface TabTitles { DASHBOARD: string; LOG: string; PROGRESS: string; AI_COACH: string; }

export const STORAGE_KEYS: StorageKeys = {
  TRAINING_DATA: 'training_data', LAST_UPDATE: 'last_update',
  DEEPSEEK_API_KEY: 'deepseek_api_key', DEEPSEEK_CONFIG: 'deepseek_config', USER_PREFERENCES: 'user_preferences',
  XUNJI_TOKEN: 'xunji_token'
};

export const DEEPSEEK_API: DeepSeekApi = {
  BASE_URL: 'https://api.deepseek.com', CHAT_ENDPOINT: '/chat/completions',
  MODEL: 'deepseek-chat', TIMEOUT_MS: 60000
};

export const TAB_TITLES: TabTitles = {
  DASHBOARD: '首页', LOG: '训练', PROGRESS: '进展', AI_COACH: 'AI教练'
};
