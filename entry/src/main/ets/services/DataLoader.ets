import util from '@ohos.util';
import { extractRecordsFromJson } from './DataParser';
import { TrainingRecord } from '../models/TrainingRecord';
import { Storage } from './PreferencesStorage';

interface ResMgr {
  getRawFileContent(path: string): Promise<Uint8Array>;
}

interface AppContext {
  resourceManager?: ResMgr;
}

export async function loadFromRawFile(ctx: Object, fileName: string): Promise<TrainingRecord[]> {
  try {
    let rawData: Uint8Array | null = null;
    // Method 1: Context.resourceManager (standard API)
    try {
      const context = ctx as AppContext;
      if (context.resourceManager) {
        rawData = await context.resourceManager.getRawFileContent(fileName);
      }
    } catch (e) {
      console.error('Loader m1: ' + JSON.stringify(e));
    }
    // Method 2: Fallback - access via Record
    if (!rawData) {
      try {
        const mgr = (ctx as Record<string, Object>)['resourceManager'] as Record<string, Object>;
        const func = mgr['getRawFileContent'] as Function;
        rawData = await func(fileName) as Uint8Array;
      } catch (e) {
        console.error('Loader m2: ' + JSON.stringify(e));
      }
    }
    // Method 3: Try getRawFileContentSync if available
    if (!rawData) {
      try {
        const mgr = (ctx as Record<string, Object>)['resourceManager'] as Record<string, Object>;
        const func = mgr['getRawFileContentSync'] as Function;
        rawData = func(fileName) as Uint8Array;
      } catch (e) {
        console.error('Loader m3: ' + JSON.stringify(e));
      }
    }
    if (!rawData || rawData.length === 0) {
      console.error('Loader: all methods returned empty for ' + fileName);
      return [];
    }

    const uint8: Uint8Array = new Uint8Array(rawData);
    const jsonStr = new util.TextDecoder('utf-8').decodeToString(uint8);
    const parsed = JSON.parse(jsonStr) as Record<string, Object>;
    const records = extractRecordsFromJson(parsed);
    return records;
  } catch (err) {
    console.error('Loader catch: ' + JSON.stringify(err));
    return [];
  }
}

export async function loadFromCache(): Promise<TrainingRecord[]> {
  const c = await Storage.getTrainingData();
  return (c as TrainingRecord[]) || [];
}

export function mergeRecords(a: TrainingRecord[], b: TrainingRecord[]): TrainingRecord[] {
  const m = new Map<string, TrainingRecord>();
  for (const r of a) m.set(r.id, r);
  for (const r of b) m.set(r.id, r);
  return Array.from(m.values()).sort((x, y) => y.date.localeCompare(x.date) || y.startTime - x.startTime);
}
