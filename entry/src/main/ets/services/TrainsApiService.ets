import http from '@ohos.net.http';
import { TrainingRecord, TrainingType, Exercise, ExerciseSet } from '../models/TrainingRecord';
import { parseWeight } from '../utils/UnitConverter';
import { Storage } from './PreferencesStorage';

const BASE_URL = 'https://trains.xunjiapp.cn';
const READ_ENDPOINT = '/api_trains_for_llm_v2';
const WRITE_ENDPOINT = '/api_upsert_trains_for_llm_v2';
const TIMEOUT_MS = 30000;

const lastFetchTime: Record<string, number> = {};
const MIN_FETCH_INTERVAL = 15000;
const MIN_FETCH_FULL_INTERVAL = 30000;
const MIN_WRITE_INTERVAL = 45000;

const APPLE_HEALTH_NAMES: string[] = ['Running', 'Walking', 'Cycling', 'Swimming', 'Hiking'];

interface ApiSetItem {
  weight?: string;
  weight_kg?: string;
  unit?: string;
  reps?: string;
  time?: string | number;
  duration_s?: string | number;
  selfWeight?: string | boolean;
  done?: boolean;
  metrics?: Record<string, number>;
}

interface ApiSubSet {
  name?: string;
  set: ApiSetItem;
}

interface ApiSet extends ApiSetItem {
  items?: ApiSubSet[];
}

interface ApiMovement {
  name: string;
  sets: ApiSet[];
}

interface ApiTrain {
  datestr: string;
  localid?: number;
  title?: string;
  start?: number;
  end?: number;
  movements?: ApiMovement[];
}

interface ApiResData {
  trains?: ApiTrain[];
}

interface ApiResponse {
  success?: boolean;
  res?: ApiResData | ApiTrain[] | string;
  message?: string;
}

interface WriteResult {
  success: boolean;
  message?: string;
  result?: Object;
}

interface TrainMetrics {
  distance: number;
  calories: number;
  avgHeartRate: number;
  hasMetrics: boolean;
}

function newFail(msg: string): WriteResult {
  return { success: false, message: msg };
}

function canRequest(key: string, minInterval: number): boolean {
  const last = lastFetchTime[key] || 0;
  return Date.now() - last >= minInterval;
}

function markRequest(key: string): void {
  lastFetchTime[key] = Date.now();
}

function formatDateStr(d: Date): string {
  return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function getAuthHeaders(): Promise<Record<string, string>> {
  const token = await Storage.getXunjiToken();
  return {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
  };
}

function parseDuration(val?: string | number): number {
  if (val === undefined || val === null || val === '') return 0;
  const n = typeof val === 'number' ? val : parseInt('' + val);
  return isNaN(n) ? 0 : n;
}

function buildExerciseSet(item: ApiSetItem): ExerciseSet {
  const weightRaw = item.weight || item.weight_kg || '0';
  const unit = item.unit || 'kg';
  const weight = parseWeight('' + weightRaw, unit);
  const reps = parseInt(item.reps || '0');
  const durationSeconds = parseDuration(item.time ?? item.duration_s);
  return {
    setNumber: 0,
    weight: isNaN(weight) ? 0 : weight,
    reps: isNaN(reps) ? 0 : reps,
    durationSeconds: durationSeconds,
    rawWeight: weightRaw + unit,
    rawReps: item.reps || ''
  };
}

function mergeMetrics(target: TrainMetrics, metrics?: Record<string, number>): void {
  if (!metrics) return;
  target.hasMetrics = true;
  if (metrics.distance) target.distance = Math.max(target.distance, metrics.distance);
  const cal = metrics.kcal || metrics.calories || 0;
  if (cal) target.calories = Math.max(target.calories, cal);
  if (metrics.avgHeartRate) target.avgHeartRate = Math.max(target.avgHeartRate, metrics.avgHeartRate);
}

function appendExerciseSet(exercises: Exercise[], exerciseName: string, set: ExerciseSet): void {
  let exercise: Exercise | null = null;
  for (let i = 0; i < exercises.length; i++) {
    if (exercises[i].name === exerciseName) {
      exercise = exercises[i];
      break;
    }
  }
  if (!exercise) {
    exercise = { number: exercises.length + 1, name: exerciseName, sets: [], totalSets: 0 };
    exercises.push(exercise);
  }
  set.setNumber = exercise.sets.length + 1;
  exercise.sets.push(set);
  exercise.totalSets = exercise.sets.length;
}

function emptyMetrics(): TrainMetrics {
  return { distance: 0, calories: 0, avgHeartRate: 0, hasMetrics: false };
}

function convertMovements(movements?: ApiMovement[], metricsOut?: TrainMetrics): Exercise[] {
  if (!movements) return [];
  const metrics = metricsOut ? metricsOut : emptyMetrics();
  const exercises: Exercise[] = [];
  for (let i = 0; i < movements.length; i++) {
    const movement = movements[i];
    if (!movement.sets) continue;
    for (let j = 0; j < movement.sets.length; j++) {
      const set = movement.sets[j];
      mergeMetrics(metrics, set.metrics);
      if (set.items && set.items.length > 0) {
        for (const item of set.items) {
          const sub = item.set;
          mergeMetrics(metrics, sub.metrics);
          const exName = item.name || movement.name;
          appendExerciseSet(exercises, exName, buildExerciseSet(sub));
        }
      } else {
        appendExerciseSet(exercises, movement.name, buildExerciseSet(set));
      }
    }
  }
  for (let i = 0; i < exercises.length; i++) {
    exercises[i].number = i + 1;
  }
  return exercises;
}

function isAppleHealthMovement(name: string): boolean {
  for (const n of APPLE_HEALTH_NAMES) {
    if (name === n) return true;
  }
  return false;
}

function detectTrainingType(train: ApiTrain, exercises: Exercise[], metrics: TrainMetrics): TrainingType {
  if (exercises.length > 0) {
    let hasStrength = false;
    for (const ex of exercises) {
      for (const s of ex.sets) {
        if (s.weight > 0 || s.reps > 0) hasStrength = true;
      }
      if (isAppleHealthMovement(ex.name)) return TrainingType.APPLE_HEALTH;
    }
    if (hasStrength) return TrainingType.STRENGTH;
  }
  if (metrics.hasMetrics) return TrainingType.CARDIO;
  if (train.title && train.title.indexOf('苹果健康') >= 0) return TrainingType.APPLE_HEALTH;
  if (exercises.length === 0) return TrainingType.CARDIO;
  return TrainingType.STRENGTH;
}

function convertTrainToRecord(train: ApiTrain, index: number = 0): TrainingRecord {
  const metrics: TrainMetrics = { distance: 0, calories: 0, avgHeartRate: 0, hasMetrics: false };
  const dateStr = train.datestr || '';
  const start = train.start || 0;
  const end = train.end || 0;
  const durationMin = (end > start) ? Math.round((end - start) / 60000) : 0;
  const exercises = convertMovements(train.movements, metrics);
  const type = detectTrainingType(train, exercises, metrics);
  const localId = train.localid !== undefined ? train.localid : (Date.now() % 100000 + index);
  const record: TrainingRecord = {
    date: dateStr,
    rawDate: dateStr,
    id: 'xj_' + localId,
    name: train.title || '训练',
    startTime: start,
    endTime: end,
    durationMinutes: durationMin,
    type: type,
    exercises: exercises,
    notes: '',
    raw: ''
  };
  if (metrics.hasMetrics) {
    if (metrics.distance > 0) record.distance = metrics.distance;
    if (metrics.calories > 0) record.calories = metrics.calories;
    if (metrics.avgHeartRate > 0) record.avgHeartRate = metrics.avgHeartRate;
  }
  return record;
}

function parseTooFrequentMs(res: Object | ApiTrain[] | string | undefined): number {
  if (typeof res !== 'string') return 0;
  const match = res.match(/retry after (\d+)s/i);
  if (!match) return 0;
  return parseInt(match[1]) * 1000;
}

function extractTrains(res: Object | ApiTrain[] | string | undefined): ApiTrain[] | null {
  if (!res || typeof res === 'string') return null;
  if (Array.isArray(res)) return res as ApiTrain[];
  const data = res as ApiResData;
  if (data.trains !== undefined) return data.trains;
  return null;
}

function parseResponseBody(response: http.HttpResponse): ApiResponse | null {
  try {
    if (typeof response.result === 'string') {
      return JSON.parse(response.result) as ApiResponse;
    }
    return response.result as ApiResponse;
  } catch (err) {
    console.error('TrainsApi parse error');
    return null;
  }
}

interface DayFetchOutcome {
  records: TrainingRecord[] | null;
  retryMs: number;
}

async function requestDayOnce(dateStr: string, includeFullData: boolean): Promise<DayFetchOutcome> {
  const token = await Storage.getXunjiToken();
  if (!token) return { records: null, retryMs: 0 };

  const httpRequest = http.createHttp();
  try {
    const body = JSON.stringify({
      schema_version: 'train_open_api_v2',
      datestr: dateStr,
      include_full_data: includeFullData
    });

    const response = await httpRequest.request(BASE_URL + READ_ENDPOINT, {
      method: http.RequestMethod.POST,
      header: await getAuthHeaders(),
      extraData: body,
      connectTimeout: TIMEOUT_MS,
      readTimeout: TIMEOUT_MS
    });

    if (response.responseCode !== 200) {
      console.warn('TrainsApi: fetch ' + dateStr + ' failed with ' + response.responseCode);
      return { records: null, retryMs: 0 };
    }

    const result = parseResponseBody(response);
    if (!result) return { records: null, retryMs: 0 };

    const retryMs = parseTooFrequentMs(result.res);
    if (retryMs > 0) {
      return { records: null, retryMs: retryMs };
    }

    const trains = extractTrains(result.res);
    if (trains !== null) {
      markRequest(dateStr);
      return { records: trains.map((t, i) => convertTrainToRecord(t, i)), retryMs: 0 };
    }

    if (result.success === false) {
      console.warn('TrainsApi: fetch ' + dateStr + ' returned no trains');
    }
    return { records: null, retryMs: 0 };
  } catch (err) {
    console.error('TrainsApi fetchDay error');
    return { records: null, retryMs: 0 };
  } finally {
    httpRequest.destroy();
  }
}

async function requestDayWithRetry(dateStr: string, includeFullData: boolean): Promise<TrainingRecord[] | null> {
  const first = await requestDayOnce(dateStr, includeFullData);
  if (first.records !== null) return first.records;

  if (first.retryMs > 0) {
    await delay(first.retryMs + 500);
    const second = await requestDayOnce(dateStr, includeFullData);
    if (second.records !== null) return second.records;
  }

  const cached = await Storage.getDayCache(dateStr);
  return cached.length > 0 ? cached : null;
}

/**
 * 读取指定日期的训练数据（按 datestr 缓存，限频时返回缓存）
 */
export async function fetchDay(dateStr: string, includeFullData: boolean = false, forceRefresh: boolean = false): Promise<TrainingRecord[]> {
  const cached = await Storage.getDayCache(dateStr);
  const interval = includeFullData ? MIN_FETCH_FULL_INTERVAL : MIN_FETCH_INTERVAL;

  if (!forceRefresh && cached.length > 0 && !canRequest(dateStr, interval)) {
    return cached;
  }

  const token = await Storage.getXunjiToken();
  if (!token) {
    return cached;
  }

  if (!forceRefresh && !canRequest(dateStr, interval)) {
    return cached;
  }

  const records = await requestDayWithRetry(dateStr, includeFullData);
  if (records !== null) {
    await Storage.saveDayCache(dateStr, records);
    return records;
  }

  return cached;
}

/**
 * 读取最近 N 天的训练数据
 */
export async function fetchRecentDays(days: number): Promise<TrainingRecord[]> {
  const allRecords: TrainingRecord[] = [];
  const seenIds = new Set<string>();
  const end = new Date();
  const token = await Storage.getXunjiToken();
  if (!token) return [];

  for (let i = 0; i < days; i++) {
    const d = new Date(end.getTime() - i * 86400000);
    const dateStr = formatDateStr(d);
    const records = await fetchDay(dateStr);
    for (const r of records) {
      if (!seenIds.has(r.id)) {
        seenIds.add(r.id);
        allRecords.push(r);
      }
    }
  }
  return allRecords;
}

/**
 * 写回训练数据（默认 dry_run，需用户确认后再正式写回）
 */
export async function writeTrains(trains: ApiTrain[], dryRun: boolean = true): Promise<WriteResult> {
  if (!canRequest('write', MIN_WRITE_INTERVAL)) {
    return newFail('操作太频繁，请等待后重试');
  }

  const token = await Storage.getXunjiToken();
  if (!token) {
    return newFail('未配置训记 API Key，请在 App 设置中填写');
  }

  const httpRequest = http.createHttp();
  try {
    const body = JSON.stringify({
      schema_version: 'train_open_api_v2',
      client_request_id: 'app_' + Date.now(),
      dry_run: dryRun,
      include_full_data: false,
      res: trains
    });

    const response = await httpRequest.request(BASE_URL + WRITE_ENDPOINT, {
      method: http.RequestMethod.POST,
      header: await getAuthHeaders(),
      extraData: body,
      connectTimeout: TIMEOUT_MS,
      readTimeout: TIMEOUT_MS
    });

    markRequest('write');

    if (response.responseCode !== 200) {
      return newFail('写回失败: ' + response.responseCode);
    }

    const result = parseResponseBody(response);
    if (!result) return newFail('响应解析失败');

    const retryMs = parseTooFrequentMs(result.res);
    if (retryMs > 0) {
      return newFail('操作太频繁，请 ' + Math.ceil(retryMs / 1000) + ' 秒后重试');
    }

    const wr: WriteResult = { success: result.success === true, message: result.message, result: result.res };
    return wr;
  } catch (err) {
    console.error('TrainsApi write error');
    return newFail('网络错误');
  } finally {
    httpRequest.destroy();
  }
}
