import { TrainingRecord, TrainingType } from '../models/TrainingRecord';
import { DashboardStats, EMPTY_DASHBOARD_STATS } from '../models/DashboardStats';
import { DeepSeekConfig, DEFAULT_DEEPSEEK_CONFIG } from '../models/AiConversation';
import { computeDashboardStats, getExerciseHistory, getAllExerciseNames } from '../services/StatisticsEngine';
import { loadFromRawFile, loadFromCache, mergeRecords } from '../services/DataLoader';
import { fetchRecentDays } from '../services/TrainsApiService';
import { Storage } from '../services/PreferencesStorage';

interface HP { date: string; maxWeight: number; maxOneRm: number; totalVolume: number; }
export enum LoadState { LOADING = 'loading', LOADED = 'loaded', ERROR = 'error', EMPTY = 'empty' }

function buildSampleData(): TrainingRecord[] {
  const today = new Date();
  const ts = (d: number) => new Date(today.getTime() - d * 86400000);
  const ds = (d: number) => ts(d).getFullYear() + '-' + String(ts(d).getMonth() + 1).padStart(2, '0') + '-' + String(ts(d).getDate()).padStart(2, '0');
  const samples: TrainingRecord[] = [
    { date: ds(0), rawDate: ds(0), id: 'sample_1', name: '推胸训练', startTime: 0, endTime: 0, durationMinutes: 45, type: TrainingType.STRENGTH,
      exercises: [{ number: 1, name: '杠铃卧推', sets: [{ setNumber: 1, weight: 60, reps: 8, durationSeconds: 0, rawWeight: '60kg', rawReps: '8' }, { setNumber: 2, weight: 70, reps: 6, durationSeconds: 0, rawWeight: '70kg', rawReps: '6' }, { setNumber: 3, weight: 80, reps: 4, durationSeconds: 0, rawWeight: '80kg', rawReps: '4' }], totalSets: 3 },
        { number: 2, name: '哑铃飞鸟', sets: [{ setNumber: 1, weight: 15, reps: 12, durationSeconds: 0, rawWeight: '15kg', rawReps: '12' }], totalSets: 1 }],
      notes: '', raw: '' },
    { date: ds(2), rawDate: ds(2), id: 'sample_2', name: '腿部训练', startTime: 0, endTime: 0, durationMinutes: 60, type: TrainingType.STRENGTH,
      exercises: [{ number: 1, name: '深蹲', sets: [{ setNumber: 1, weight: 80, reps: 8, durationSeconds: 0, rawWeight: '80kg', rawReps: '8' }, { setNumber: 2, weight: 100, reps: 5, durationSeconds: 0, rawWeight: '100kg', rawReps: '5' }, { setNumber: 3, weight: 120, reps: 3, durationSeconds: 0, rawWeight: '120kg', rawReps: '3' }], totalSets: 3 },
        { number: 2, name: '硬拉', sets: [{ setNumber: 1, weight: 100, reps: 5, durationSeconds: 0, rawWeight: '100kg', rawReps: '5' }, { setNumber: 2, weight: 130, reps: 3, durationSeconds: 0, rawWeight: '130kg', rawReps: '3' }], totalSets: 2 }],
      notes: '', raw: '' },
    { date: ds(4), rawDate: ds(4), id: 'sample_3', name: '上肢训练', startTime: 0, endTime: 0, durationMinutes: 50, type: TrainingType.STRENGTH,
      exercises: [{ number: 1, name: '杠铃卧推', sets: [{ setNumber: 1, weight: 65, reps: 8, durationSeconds: 0, rawWeight: '65kg', rawReps: '8' }, { setNumber: 2, weight: 75, reps: 5, durationSeconds: 0, rawWeight: '75kg', rawReps: '5' }], totalSets: 2 },
        { number: 2, name: '哑铃推肩', sets: [{ setNumber: 1, weight: 20, reps: 10, durationSeconds: 0, rawWeight: '20kg', rawReps: '10' }], totalSets: 1 },
        { number: 3, name: '杠铃划船', sets: [{ setNumber: 1, weight: 60, reps: 8, durationSeconds: 0, rawWeight: '60kg', rawReps: '8' }], totalSets: 1 }],
      notes: '', raw: '' },
  ];
  const todayStr = ds(0);
  return samples.map(s => { s.raw = JSON.stringify(s); return s; });
}

class VM {
  private R: TrainingRecord[] = [];
  private S: DashboardStats = EMPTY_DASHBOARD_STATS;
  private N: string[] = [];
  private D: boolean = true;
  loadState: LoadState = LoadState.EMPTY;
  loadError: string = '';
  syncError: string = '';
  lastSyncDate: string = '';
  xunjiTokenConfigured: boolean = false;
  deepSeekConfig: DeepSeekConfig = DEFAULT_DEEPSEEK_CONFIG;

  get allRecords(): TrainingRecord[] { return this.R; }
  get dashboardStats(): DashboardStats {
    if (this.D) { this.S = computeDashboardStats(this.R); this.N = getAllExerciseNames(this.R); this.D = false; }
    return this.S;
  }
  get exerciseNames(): string[] { if (this.D) this.dashboardStats; return this.N; }

  async initialize(ctx: Object): Promise<void> {
    this.loadState = LoadState.LOADING;
    try {
      let r: TrainingRecord[] = await loadFromCache();
      const rr = await loadFromRawFile(ctx, 'training_data.json');
      if (rr.length > 0) r = mergeRecords(r, rr);
      // 如果本地数据为空，使用内置示例数据
      if (r.length === 0) {
        r = buildSampleData();
        console.info('Using built-in sample data');
      }
      this.deepSeekConfig.apiKey = await Storage.getApiKey();
      this.lastSyncDate = await Storage.getLastSyncDate();
      this.xunjiTokenConfigured = (await Storage.getXunjiToken()).length > 0;
      this.R = r; this.D = true;

      if (r.length === 0) {
        this.loadState = LoadState.EMPTY;
      } else {
        this.loadState = LoadState.LOADED;
        Storage.saveTrainingData(r);
      }
    } catch (err) {
      // 出错时也使用示例数据
      this.R = buildSampleData();
      this.D = true;
      this.loadState = LoadState.LOADED;
      this.loadError = (err as Error).message || 'error';
      console.error('Init error, using sample data: ' + JSON.stringify(err));
    }

    if (this.xunjiTokenConfigured) {
      this.syncFromApi().then(() => {}).catch(() => {});
    }
  }

  async syncFromApi(): Promise<number> {
    this.syncError = '';
    if (!this.xunjiTokenConfigured) {
      this.syncError = '请先配置训记 API Key';
      return 0;
    }
    try {
      const apiRecords = await fetchRecentDays(14);
      if (apiRecords.length > 0) {
        this.R = mergeRecords(this.R, apiRecords);
        this.D = true;
        Storage.saveTrainingData(this.R);
        const today = new Date();
        const dateStr = today.getFullYear() + '-' + String(today.getMonth() + 1).padStart(2, '0') + '-' + String(today.getDate()).padStart(2, '0');
        this.lastSyncDate = dateStr;
        Storage.saveLastSyncDate(dateStr);
        console.info('Sync: merged ' + apiRecords.length + ' records from Xunji API');
        return apiRecords.length;
      }
      console.info('Sync: no new records from API');
      return 0;
    } catch (err) {
      this.syncError = (err as Error).message || '同步失败';
      console.error('Sync: API error ' + JSON.stringify(err));
      return 0;
    }
  }

  addRecords(r: TrainingRecord[]): void {
    if (r.length === 0) return;
    this.R = mergeRecords(this.R, r); this.D = true; this.loadState = LoadState.LOADED;
    Storage.saveTrainingData(this.R);
  }

  getExerciseHistory(name: string): HP[] { return getExerciseHistory(this.R, name) as HP[]; }
  async updateApiKey(k: string): Promise<void> { this.deepSeekConfig.apiKey = k; await Storage.saveApiKey(k); }

  async updateXunjiToken(k: string): Promise<void> {
    const token = k.trim();
    await Storage.saveXunjiToken(token);
    this.xunjiTokenConfigured = token.length > 0;
  }
}
export const viewModel = new VM();
