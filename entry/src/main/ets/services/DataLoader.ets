/**
 * 数据加载器
 * 从 rawfile 加载 JSON 训练数据
 */

import util from '@ohos.util';
import { extractRecordsFromJson } from './DataParser';
import { TrainingRecord } from '../models/TrainingRecord';
import { Storage } from './PreferencesStorage';

/** 从rawfile加载JSON并解析为TrainingRecord[] */
export async function loadFromRawFile(context: any, fileName: string = 'training_data.json'): Promise<TrainingRecord[]> {
  try {
    // 鸿蒙资源管理器
    const resourceMgr = context.resourceManager;
    const data = await resourceMgr.getRawFileContent(fileName);

    if (!data || data.length === 0) {
      console.warn('DataLoader: rawfile is empty');
      return [];
    }

    // Uint8Array → string
    const decoder = util.TextDecoder.create('utf-8');
    const jsonStr = decoder.decodeToString(data);

    const jsonData = JSON.parse(jsonStr);
    const records = extractRecordsFromJson(jsonData);

    console.info(`DataLoader: loaded ${records.length} records from ${fileName}`);
    return records;
  } catch (err) {
    console.error(`DataLoader: failed to load ${fileName}`, JSON.stringify(err));
    return [];
  }
}

/** 从Preferences缓存加载 */
export async function loadFromCache(): Promise<TrainingRecord[]> {
  const cached = await Storage.getTrainingData<TrainingRecord[]>([]);
  if (cached && cached.length > 0) {
    console.info(`DataLoader: loaded ${cached.length} records from cache`);
    return cached;
  }
  return [];
}

/**
 * 合并新数据到已有的记录中（去重）
 */
export function mergeRecords(existing: TrainingRecord[], incoming: TrainingRecord[]): TrainingRecord[] {
  const idMap = new Map<string, TrainingRecord>();

  // 先加入现有记录
  for (const r of existing) {
    idMap.set(r.id, r);
  }

  // 合并新记录
  for (const r of incoming) {
    if (!idMap.has(r.id)) {
      idMap.set(r.id, r);
    }
  }

  // 按日期排序（最新的在前）
  return Array.from(idMap.values()).sort(
    (a, b) => b.date.localeCompare(a.date) || b.startTime - a.startTime
  );
}
