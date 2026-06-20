/**
 * 核心：CSV训练记录解析器
 *
 * 处理4种记录类型：
 * - Type A (力量训练): YYMMDD,id:...,训练名,train_time:...,N.动作名,N组,重量,次数次,...
 * - Type B (有氧): ...,1.有氧训练,距离,热量kcal,心率bpm,time:Xs
 * - Type C (Apple Health): ...,1.苹果健康训练,热量kcal,time:Xs
 * - Type D (最小记录): 缺少train_time等字段
 */

import { TrainingRecord, TrainingType, Exercise, ExerciseSet, detectTrainingType } from '../models/TrainingRecord';
import { yymmddToDateStr } from '../utils/DateUtils';
import { parseWeight } from '../utils/UnitConverter';

/** 解析单条CSV记录 → TrainingRecord */
export function parseCsvRecord(csv: string): TrainingRecord | null {
  if (!csv || csv.trim().length === 0) return null;

  const trimmed = csv.trim();
  const type = detectTrainingType(trimmed);
  const fields = splitCsvFields(trimmed);

  switch (type) {
    case TrainingType.CARDIO:
      return parseCardioRecord(trimmed, fields);
    case TrainingType.APPLE_HEALTH:
      return parseAppleHealthRecord(trimmed, fields);
    case TrainingType.STRENGTH:
      return parseStrengthRecord(trimmed, fields);
    default:
      return parseMinimalRecord(trimmed, fields);
  }
}

/**
 * 智能CSV字段分割
 * 训记CSV中value可能包含逗号（如备注），需要用引号包裹
 */
function splitCsvFields(csv: string): string[] {
  const fields: string[] = [];
  let current = '';
  let inQuotes = false;

  for (let i = 0; i < csv.length; i++) {
    const ch = csv[i];
    if (ch === '"') {
      inQuotes = !inQuotes;
    } else if (ch === ',' && !inQuotes) {
      fields.push(current.trim());
      current = '';
    } else {
      current += ch;
    }
  }
  fields.push(current.trim());
  return fields;
}

/** 提取头部字段（日期、ID、名称、时间） */
function extractHeader(fields: string[]): {
  rawDate: string;
  id: string;
  name: string;
  startTime: number;
  endTime: number;
  notes: string;
  bodyStartIndex: number;
} {
  const rawDate = fields[0] || '';
  let id = '';
  let name = '';
  let startTime = 0;
  let endTime = 0;
  let notes = '';
  let bodyStartIndex = fields.length;

  // 遍历前几个字段提取已知键值对
  for (let i = 1; i < fields.length; i++) {
    const f = fields[i];
    if (f.startsWith('id:')) {
      id = f.substring(3);
    } else if (f.startsWith('train_time:')) {
      const times = f.substring(11).split('-');
      startTime = parseInt(times[0]) || 0;
      endTime = parseInt(times[1]) || 0;
    } else if (f.startsWith('date:')) {
      // 日期覆盖（某些记录有此字段）
    } else if (/^\d+\.\S/.test(f)) {
      // 遇到第一个 N.动作名，标记为body开始
      bodyStartIndex = i;
      break;
    } else if (i >= 2 && !f.startsWith('id:') && !f.startsWith('train_time:') && !f.startsWith('date:')) {
      // 在id之后、动作之前的非标记字段 → 训练名称
      if (!name) {
        name = f;
      }
    }
  }

  // 如果没有找到动作名（有氧/Apple Health类型），body从第4个字段后开始
  if (bodyStartIndex === fields.length) {
    bodyStartIndex = Math.min(4, fields.length);
  }

  // 收集备注：最后一个动作之后到结束的文本
  // 备注通常在全部动作完成后以引号包裹
  const lastField = fields[fields.length - 1];
  if (lastField.includes('备注') || lastField.includes('note') || lastField.startsWith('"')) {
    notes = lastField.replace(/^"|"$/g, '');
  }

  return { rawDate, id, name, startTime, endTime, notes, bodyStartIndex };
}

/** 解析力量训练记录 (Type A) */
function parseStrengthRecord(csv: string, fields: string[]): TrainingRecord {
  const header = extractHeader(fields);
  const date = yymmddToDateStr(header.rawDate);

  // 从 bodyStartIndex 开始解析动作
  const bodyFields = fields.slice(header.bodyStartIndex);
  const exercises = parseExercises(bodyFields);

  // 计算总组数和总吨数
  let totalDuration = header.endTime > header.startTime
    ? (header.endTime - header.startTime) / 1000 / 60
    : 0;

  return {
    date,
    rawDate: header.rawDate,
    id: header.id,
    name: header.name || '训练',
    startTime: header.startTime,
    endTime: header.endTime,
    durationMinutes: Math.round(totalDuration),
    type: TrainingType.STRENGTH,
    exercises,
    notes: header.notes,
    raw: csv
  };
}

/** 从字段列表解析出所有动作 */
function parseExercises(bodyFields: string[]): Exercise[] {
  const exercises: Exercise[] = [];

  // 第一步：按 N.动作名 分割出每个动作的字段块
  const exerciseBlocks: { name: string; fields: string[] }[] = [];
  let currentExerciseName = '';
  let currentFields: string[] = [];

  for (const f of bodyFields) {
    const match = f.match(/^(\d+)\.(.+)$/);
    if (match) {
      // 保存前一个动作
      if (currentExerciseName && currentFields.length > 0) {
        exerciseBlocks.push({ name: currentExerciseName, fields: currentFields });
      }
      currentExerciseName = match[2].trim();
      currentFields = [];
    } else {
      currentFields.push(f);
    }
  }
  // 最后一个动作
  if (currentExerciseName) {
    exerciseBlocks.push({ name: currentExerciseName, fields: currentFields });
  }

  // 第二步：解析每个动作的组
  for (const block of exerciseBlocks) {
    const sets = parseSets(block.fields);
    if (sets.length > 0) {
      exercises.push({
        number: exercises.length + 1,
        name: block.name,
        sets,
        totalSets: sets.length
      });
    }
  }

  return exercises;
}

/**
 * 解析一组字段为ExerciseSet列表
 * 字段格式: ["1组","20kg","5次","time:22s","2组","20kg","5次","time:38s",...]
 * 或简写: ["1组","10次","time:60s","2组","8次","time:60s",...] (无重量，如引体向上)
 */
function parseSets(fields: string[]): ExerciseSet[] {
  const sets: ExerciseSet[] = [];
  let currentSet: Partial<ExerciseSet> = {};
  let currentGroup: string[] = [];

  // 按 "N组" 标记分割
  for (const f of fields) {
    const setMatch = f.match(/^(\d+)组$/);
    if (setMatch) {
      // 保存前一组
      if (currentGroup.length > 0) {
        const parsed = parseSingleSet(currentGroup);
        if (parsed) sets.push(parsed);
      }
      currentGroup = [];
      currentSet = { setNumber: parseInt(setMatch[1]) };
      currentGroup.push(f);
    } else {
      currentGroup.push(f);
    }
  }
  // 最后一组
  if (currentGroup.length > 0) {
    const parsed = parseSingleSet(currentGroup);
    if (parsed) sets.push(parsed);
  }

  return sets;
}

/** 解析一组字段为单个ExerciseSet */
function parseSingleSet(group: string[]): ExerciseSet | null {
  let setNumber = 0;
  let weight = 0;
  let reps = 0;
  let durationSeconds = 0;
  let rawWeight = '';
  let rawReps = '';

  for (const f of group) {
    const setMatch = f.match(/^(\d+)组$/);
    if (setMatch) {
      setNumber = parseInt(setMatch[1]);
      continue;
    }

    const weightMatch = f.match(/^([\d.]+)\s*kg$/);
    if (weightMatch) {
      weight = parseFloat(weightMatch[1]);
      rawWeight = weightMatch[0];
      continue;
    }

    const repsMatch = f.match(/^(\d+)次$/);
    if (repsMatch) {
      reps = parseInt(repsMatch[1]);
      rawReps = repsMatch[0];
      continue;
    }

    const timeMatch = f.match(/^time:(\d+)s$/);
    if (timeMatch) {
      durationSeconds = parseInt(timeMatch[1]);
      continue;
    }

    // 仅数字+次（如 "10次" — 已匹配上方）
    // 仅数字+kg（如 "20kg" — 已匹配上方）
    // 可能是徒手动作只有次数没有重量
    const nakedReps = f.match(/^(\d+)次?$/);
    if (nakedReps && !f.includes('kg') && !f.includes('组')) {
      reps = parseInt(nakedReps[1]);
      rawReps = nakedReps[0];
      continue;
    }

    // 可能是重量但没有单位（特殊情况）
    const nakedWeight = f.match(/^(\d+(?:\.\d+)?)$/);
    if (nakedWeight && weight === 0 && reps === 0) {
      weight = parseFloat(nakedWeight[1]);
      rawWeight = nakedWeight[0];
      continue;
    }
  }

  if (setNumber === 0) return null;

  return {
    setNumber,
    weight,
    reps,
    durationSeconds,
    rawWeight,
    rawReps
  };
}

/** 解析有氧训练记录 (Type B) */
function parseCardioRecord(csv: string, fields: string[]): TrainingRecord {
  const header = extractHeader(fields);
  const date = yymmddToDateStr(header.rawDate);

  let distance = 0;
  let calories = 0;
  let avgHeartRate = 0;

  // 搜索有氧字段
  for (const f of fields) {
    const distMatch = f.match(/^([\d.]+)\s*(km|m|公里|米)?$/i);
    const calMatch = f.match(/^(\d+)\s*kcal$/i);
    const hrMatch = f.match(/^(\d+)\s*bpm$/i);

    if (calMatch) calories = parseInt(calMatch[1]);
    else if (hrMatch) avgHeartRate = parseInt(hrMatch[1]);
    else if (distMatch) {
      const val = parseFloat(distMatch[1]);
      const unit = (distMatch[2] || '').toLowerCase();
      distance = unit === 'km' || unit === '公里' ? val * 1000 : val;
    }
  }

  let totalDuration = header.endTime > header.startTime
    ? (header.endTime - header.startTime) / 1000 / 60
    : 0;

  return {
    date,
    rawDate: header.rawDate,
    id: header.id,
    name: header.name || '有氧训练',
    startTime: header.startTime,
    endTime: header.endTime,
    durationMinutes: Math.round(totalDuration),
    type: TrainingType.CARDIO,
    exercises: [],
    distance,
    calories,
    avgHeartRate,
    notes: header.notes,
    raw: csv
  };
}

/** 解析Apple Health训练记录 (Type C) */
function parseAppleHealthRecord(csv: string, fields: string[]): TrainingRecord {
  const header = extractHeader(fields);
  const date = yymmddToDateStr(header.rawDate);

  let calories = 0;

  for (const f of fields) {
    const calMatch = f.match(/^(\d+)\s*kcal$/i);
    if (calMatch) calories = parseInt(calMatch[1]);
  }

  let totalDuration = header.endTime > header.startTime
    ? (header.endTime - header.startTime) / 1000 / 60
    : 0;

  return {
    date,
    rawDate: header.rawDate,
    id: header.id,
    name: header.name || '苹果健康训练',
    startTime: header.startTime,
    endTime: header.endTime,
    durationMinutes: Math.round(totalDuration),
    type: TrainingType.APPLE_HEALTH,
    exercises: [],
    calories,
    notes: header.notes,
    raw: csv
  };
}

/** 解析最小记录 (Type D) — 只有基本信息 */
function parseMinimalRecord(csv: string, fields: string[]): TrainingRecord {
  const header = extractHeader(fields);
  const date = yymmddToDateStr(header.rawDate);

  return {
    date,
    rawDate: header.rawDate,
    id: header.id,
    name: header.name || '训练',
    startTime: header.startTime,
    endTime: header.endTime,
    durationMinutes: header.endTime > header.startTime
      ? Math.round((header.endTime - header.startTime) / 1000 / 60)
      : 0,
    type: TrainingType.MINIMAL,
    exercises: [],
    notes: header.notes,
    raw: csv
  };
}

/**
 * 批量解析多条CSV记录
 */
export function parseAllRecords(csvRecords: string[]): TrainingRecord[] {
  const records: TrainingRecord[] = [];
  const seenIds = new Set<string>();

  for (const csv of csvRecords) {
    const record = parseCsvRecord(csv);
    if (record) {
      // 去重：同一ID只保留第一次出现的记录
      if (!seenIds.has(record.id)) {
        seenIds.add(record.id);
        records.push(record);
      }
    }
  }

  // 按日期排序（最新的在前）
  records.sort((a, b) => b.date.localeCompare(a.date) || b.startTime - a.startTime);

  return records;
}

/**
 * 从JSON数据提取所有CSV记录
 * JSON结构: { "data_by_date": { "YYYY-MM-DD": [csv_string, ...] } }
 */
export function extractRecordsFromJson(jsonData: object): TrainingRecord[] {
  const allCsvs: string[] = [];

  // 支持两种格式
  const dataByDate = (jsonData as Record<string, any>)['data_by_date'];
  if (dataByDate && typeof dataByDate === 'object') {
    for (const dateStr of Object.keys(dataByDate)) {
      const records = dataByDate[dateStr];
      if (Array.isArray(records)) {
        for (const r of records) {
          if (typeof r === 'string') {
            allCsvs.push(r);
          }
        }
      }
    }
  } else if (Array.isArray(jsonData)) {
    // 直接是数组格式
    for (const item of jsonData) {
      if (typeof item === 'string') {
        allCsvs.push(item);
      }
    }
  }

  return parseAllRecords(allCsvs);
}
