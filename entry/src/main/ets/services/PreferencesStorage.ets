/**
 * 本地缓存 / 偏好存储
 * 使用鸿蒙 Preferences 实现数据持久化
 */

import preferences from '@ohos.data.preferences';
import { STORAGE_KEYS } from '../utils/Constants';

let preferencesApi: preferences.Preferences | null = null;

/** 初始化Preferences（在Ability onCreate时调用） */
export async function initPreferences(context: any): Promise<void> {
  try {
    preferencesApi = await preferences.getPreferences(context, 'training_assistant_prefs');
  } catch (err) {
    console.error('Preferences init failed', JSON.stringify(err));
  }
}

/** 获取Preferences实例 */
function getPrefs(): preferences.Preferences {
  if (!preferencesApi) {
    throw new Error('Preferences not initialized. Call initPreferences first.');
  }
  return preferencesApi;
}

/** 保存字符串值 */
export async function saveString(key: string, value: string): Promise<void> {
  try {
    const prefs = getPrefs();
    await prefs.put(key, value);
    await prefs.flush();
  } catch (err) {
    console.error(`saveString failed for key=${key}`, JSON.stringify(err));
  }
}

/** 读取字符串值 */
export async function getString(key: string, defaultValue: string = ''): Promise<string> {
  try {
    const prefs = getPrefs();
    return await prefs.get(key, defaultValue);
  } catch (err) {
    console.error(`getString failed for key=${key}`, JSON.stringify(err));
    return defaultValue;
  }
}

/** 保存JSON对象 */
export async function saveJson(key: string, value: object): Promise<void> {
  await saveString(key, JSON.stringify(value));
}

/** 读取JSON对象 */
export async function getJson<T>(key: string, defaultValue: T): Promise<T> {
  const str = await getString(key, '');
  if (!str) return defaultValue;
  try {
    return JSON.parse(str) as T;
  } catch {
    return defaultValue;
  }
}

/** 保存数字值 */
export async function saveNumber(key: string, value: number): Promise<void> {
  try {
    const prefs = getPrefs();
    await prefs.put(key, value);
    await prefs.flush();
  } catch (err) {
    console.error(`saveNumber failed for key=${key}`, JSON.stringify(err));
  }
}

/** 读取数字值 */
export async function getNumber(key: string, defaultValue: number = 0): Promise<number> {
  try {
    const prefs = getPrefs();
    return await prefs.get(key, defaultValue);
  } catch {
    return defaultValue;
  }
}

/** 删除键 */
export async function remove(key: string): Promise<void> {
  try {
    const prefs = getPrefs();
    await prefs.delete(key);
    await prefs.flush();
  } catch (err) {
    console.error(`remove failed for key=${key}`, JSON.stringify(err));
  }
}

/** 清除所有数据 */
export async function clearAll(): Promise<void> {
  try {
    const prefs = getPrefs();
    await prefs.clear();
    await prefs.flush();
  } catch (err) {
    console.error('clearAll failed', JSON.stringify(err));
  }
}

// 便利方法
export const Storage = {
  /** 缓存解析后的训练数据 */
  saveTrainingData: (records: object) => saveJson(STORAGE_KEYS.TRAINING_DATA, records),
  getTrainingData: <T>(defaultVal: T) => getJson<T>(STORAGE_KEYS.TRAINING_DATA, defaultVal),

  /** DeepSeek API Key */
  saveApiKey: (key: string) => saveString(STORAGE_KEYS.DEEPSEEK_API_KEY, key),
  getApiKey: () => getString(STORAGE_KEYS.DEEPSEEK_API_KEY, ''),

  /** 最后更新时间 */
  saveLastUpdate: (ts: number) => saveNumber(STORAGE_KEYS.LAST_UPDATE, ts),
  getLastUpdate: () => getNumber(STORAGE_KEYS.LAST_UPDATE, 0),
};
