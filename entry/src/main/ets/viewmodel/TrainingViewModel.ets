import { TrainingRecord } from '../models/TrainingRecord';
import { DashboardStats, EMPTY_DASHBOARD_STATS } from '../models/DashboardStats';
import { DeepSeekConfig, DEFAULT_DEEPSEEK_CONFIG } from '../models/AiConversation';
import { computeDashboardStats, getExerciseHistory, getAllExerciseNames } from '../services/StatisticsEngine';
import { loadFromRawFile, loadFromCache, mergeRecords } from '../services/DataLoader';
import { Storage } from '../services/PreferencesStorage';

interface HP { date: string; maxWeight: number; maxOneRm: number; totalVolume: number; }
export enum LoadState { LOADING = 'loading', LOADED = 'loaded', ERROR = 'error', EMPTY = 'empty' }

class VM {
  private R: TrainingRecord[] = [];
  private S: DashboardStats = EMPTY_DASHBOARD_STATS;
  private N: string[] = [];
  private D: boolean = true;
  loadState: LoadState = LoadState.EMPTY;
  loadError: string = '';
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
      this.deepSeekConfig.apiKey = await Storage.getApiKey();
      this.R = r; this.D = true;
      if (r.length === 0) this.loadState = LoadState.EMPTY;
      else { this.loadState = LoadState.LOADED; Storage.saveTrainingData(r); }
    } catch (err) {
      this.loadState = LoadState.ERROR;
      this.loadError = (err as Error).message || 'error';
    }
  }

  addRecords(r: TrainingRecord[]): void {
    if (r.length === 0) return;
    this.R = mergeRecords(this.R, r); this.D = true; this.loadState = LoadState.LOADED;
    Storage.saveTrainingData(this.R);
  }

  getExerciseHistory(name: string): HP[] { return getExerciseHistory(this.R, name) as HP[]; }
  async updateApiKey(k: string): Promise<void> { this.deepSeekConfig.apiKey = k; await Storage.saveApiKey(k); }
}
export const viewModel = new VM();
