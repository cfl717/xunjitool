/**
 * 全局状态管理 — TrainingViewModel 单例
 *
 * MVVM 模式：各页面通过 @State 观察此单体的变化。
 * 负责：数据加载/刷新 → 统计计算 → 派生数据缓存
 */

import { TrainingRecord, TrainingType } from '../models/TrainingRecord';
import { DashboardStats, EMPTY_DASHBOARD_STATS } from '../models/DashboardStats';
import { DeepSeekConfig, DEFAULT_DEEPSEEK_CONFIG, ChatMessage, ChatRole } from '../models/AiConversation';
import { computeDashboardStats, getExerciseHistory, getAllExerciseNames } from '../services/StatisticsEngine';
import { loadFromRawFile, loadFromCache, mergeRecords } from '../services/DataLoader';
import { Storage } from '../services/PreferencesStorage';

/** 数据加载状态 */
export enum LoadState {
  LOADING = 'loading',
  LOADED = 'loaded',
  ERROR = 'error',
  EMPTY = 'empty'
}

class TrainingViewModel {
  // 原始数据
  private _allRecords: TrainingRecord[] = [];

  // 计算后的统计缓存
  private _cachedStats: DashboardStats = EMPTY_DASHBOARD_STATS;
  private _cachedExerciseNames: string[] = [];
  private _statsDirty: boolean = true;

  // 公开可观察状态
  loadState: LoadState = LoadState.EMPTY;
  loadError: string = '';

  // DeepSeek配置
  deepSeekConfig: DeepSeekConfig = { ...DEFAULT_DEEPSEEK_CONFIG };

  /** 获取所有训练记录 */
  get allRecords(): TrainingRecord[] {
    return this._allRecords;
  }

  /** 获取仪表盘统计 */
  get dashboardStats(): DashboardStats {
    if (this._statsDirty) {
      this._cachedStats = computeDashboardStats(this._allRecords);
      this._cachedExerciseNames = getAllExerciseNames(this._allRecords);
      this._statsDirty = false;
    }
    return this._cachedStats;
  }

  /** 获取所有动作名称列表 */
  get exerciseNames(): string[] {
    if (this._statsDirty) {
      this.dashboardStats; // 触发计算
    }
    return this._cachedExerciseNames;
  }

  /** 初始化 — 加载数据 */
  async initialize(context: any): Promise<void> {
    this.loadState = LoadState.LOADING;

    try {
      // 1. 先从缓存加载
      const cached = await loadFromCache();
      let records: TrainingRecord[] = [...cached];

      // 2. 尝试从rawfile加载并合并
      const rawRecords = await loadFromRawFile(context);
      if (rawRecords.length > 0) {
        records = mergeRecords(records, rawRecords);
      }

      // 3. 加载DeepSeek配置
      const apiKey = await Storage.getApiKey();
      if (apiKey) {
        this.deepSeekConfig.apiKey = apiKey;
      }

      this._allRecords = records;
      this._statsDirty = true;

      if (records.length === 0) {
        this.loadState = LoadState.EMPTY;
      } else {
        this.loadState = LoadState.LOADED;
        // 缓存到Preferences
        await Storage.saveTrainingData(records);
      }
    } catch (err: any) {
      this.loadState = LoadState.ERROR;
      this.loadError = err.message || '加载失败';
      console.error('TrainingViewModel.initialize failed', JSON.stringify(err));
    }
  }

  /** 手动添加新记录 */
  addRecords(records: TrainingRecord[]): void {
    if (records.length === 0) return;
    this._allRecords = mergeRecords(this._allRecords, records);
    this._statsDirty = true;
    this.loadState = LoadState.LOADED;
    // 异步缓存
    Storage.saveTrainingData(this._allRecords);
  }

  /** 获取某动作的历史数据 */
  getExerciseHistory(exerciseName: string): ReturnType<typeof getExerciseHistory> {
    return getExerciseHistory(this._allRecords, exerciseName);
  }

  /** 更新DeepSeek API Key */
  async updateApiKey(apiKey: string): Promise<void> {
    this.deepSeekConfig.apiKey = apiKey;
    await Storage.saveApiKey(apiKey);
  }

  /** 刷新数据 */
  async refresh(context: any): Promise<void> {
    this.loadState = LoadState.LOADING;
    try {
      const rawRecords = await loadFromRawFile(context);
      if (rawRecords.length > 0) {
        this._allRecords = mergeRecords(this._allRecords, rawRecords);
        this._statsDirty = true;
        await Storage.saveTrainingData(this._allRecords);
      }
      this.loadState = LoadState.LOADED;
    } catch (err: any) {
      this.loadState = LoadState.ERROR;
      this.loadError = err.message || '刷新失败';
    }
  }
}

/** 全局单例 */
export const viewModel = new TrainingViewModel();
