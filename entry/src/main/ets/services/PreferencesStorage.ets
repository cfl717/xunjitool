import preferences from '@ohos.data.preferences';
import { TrainingRecord } from '../models/TrainingRecord';

let gPrefs: preferences.Preferences | null = null;

interface DayCacheEntry {
  fetchedAt: number;
  records: TrainingRecord[];
}

export async function initPreferences(context: Object): Promise<void> {
  try { gPrefs = await preferences.getPreferences(context as Context, 'training_assistant_prefs'); }
  catch (err) { console.error('Prefs: ' + JSON.stringify(err)); }
}
function p(): preferences.Preferences { if (!gPrefs) throw new Error('no prefs'); return gPrefs; }
export async function saveString(k: string, v: string): Promise<void> { try { await p().put(k, v); await p().flush(); } catch (e) {} }
export async function getString(k: string, d: string): Promise<string> { try { return await p().get(k, d) as string; } catch (e) { return d; } }
export async function saveNumber(k: string, v: number): Promise<void> { try { await p().put(k, v); await p().flush(); } catch (e) {} }
export async function getNumber(k: string, d: number): Promise<number> { try { return await p().get(k, d) as number; } catch (e) { return d; } }

class Store {
  async saveTrainingData(v: Object) { await saveString('training_data', JSON.stringify(v)); }
  async getTrainingData(): Promise<Object> { const s = await getString('training_data', ''); return s ? JSON.parse(s) : []; }
  async saveApiKey(k: string) { await saveString('deepseek_api_key', k); }
  async getApiKey(): Promise<string> { return getString('deepseek_api_key', ''); }
  async saveLastUpdate(t: number) { await saveNumber('last_update', t); }
  async getLastUpdate(): Promise<number> { return getNumber('last_update', 0); }
  async saveChatMessages(msgs: Object[]): Promise<void> {
    const trimmed = msgs.slice(-50);
    await saveString('chat_messages', JSON.stringify(trimmed));
  }
  async getChatMessages(): Promise<Object[]> {
    const s = await getString('chat_messages', '');
    return s ? JSON.parse(s) : [];
  }
  async saveXunjiToken(t: string) { await saveString('xunji_token', t); }
  async getXunjiToken(): Promise<string> { return getString('xunji_token', ''); }
  async saveLastSyncDate(d: string) { await saveString('last_sync_date', d); }
  async getLastSyncDate(): Promise<string> { return getString('last_sync_date', ''); }

  private async loadDayCacheMap(): Promise<Record<string, DayCacheEntry>> {
    const s = await getString('xunji_day_cache', '');
    if (!s) return {};
    try { return JSON.parse(s) as Record<string, DayCacheEntry>; }
    catch (e) { return {}; }
  }

  async getDayCache(dateStr: string): Promise<TrainingRecord[]> {
    const map = await this.loadDayCacheMap();
    const entry = map[dateStr];
    return entry ? entry.records : [];
  }

  async saveDayCache(dateStr: string, records: TrainingRecord[]): Promise<void> {
    const map = await this.loadDayCacheMap();
    map[dateStr] = { fetchedAt: Date.now(), records: records };
    await saveString('xunji_day_cache', JSON.stringify(map));
  }

  async getDayCacheFetchedAt(dateStr: string): Promise<number> {
    const map = await this.loadDayCacheMap();
    const entry = map[dateStr];
    return entry ? entry.fetchedAt : 0;
  }
}
export const Storage = new Store();
