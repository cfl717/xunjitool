/**
 * 统计引擎
 * 从 TrainingRecord[] 计算各种聚合统计
 */

import { TrainingRecord, TrainingType, Exercise, ExerciseSet, BIG_THREE_EXERCISES } from '../models/TrainingRecord';
import { DashboardStats, ExercisePR, WeeklyVolume, EMPTY_DASHBOARD_STATS } from '../models/DashboardStats';
import { estimateOneRm } from '../utils/EpleyFormula';
import { getWeekStart, dateStrToDate } from '../utils/DateUtils';

/** 计算完整的仪表盘统计 */
export function computeDashboardStats(records: TrainingRecord[]): DashboardStats {
  if (!records || records.length === 0) {
    return EMPTY_DASHBOARD_STATS;
  }

  const strengthRecords = records.filter(r => r.type === TrainingType.STRENGTH);
  const allDates = new Set(records.map(r => r.date));
  const totalSessions = records.length;
  const totalTrainingDays = allDates.size;

  // 总组数和总吨数
  let totalSets = 0;
  let totalVolume = 0;
  let totalDuration = 0;

  for (const r of records) {
    totalDuration += r.durationMinutes || 0;
    if (r.exercises) {
      for (const e of r.exercises) {
        for (const s of e.sets) {
          totalSets++;
          totalVolume += s.weight * s.reps;
        }
      }
    }
  }

  // 计算连续训练天数
  const sortedDates = Array.from(allDates).sort();
  const streakDays = computeStreak(sortedDates);

  // 计算全部动作PR
  const allPRs = computeAllPrs(strengthRecords);

  // 三大项PR
  const bigThreePRs = allPRs.filter(pr => BIG_THREE_EXERCISES.includes(pr.exerciseName));

  // 近4周周训练量
  const recentWeeklyVolumes = computeRecentWeeklyVolumes(records);

  return {
    totalTrainingDays,
    totalSessions,
    totalSets,
    totalVolume: Math.round(totalVolume),
    totalDurationMinutes: totalDuration,
    streakDays,
    bigThreePRs,
    allPRs,
    recentWeeklyVolumes
  };
}

/** 计算连续训练天数 */
function computeStreak(sortedDates: string[]): number {
  if (sortedDates.length === 0) return 0;

  const today = new Date();
  const todayStr = dateToStr(today);
  const yesterdayStr = dateToStr(new Date(today.getTime() - 86400000));

  // 从最后一天开始往前数
  let streak = 0;
  const lastDate = sortedDates[sortedDates.length - 1];

  // 如果最后训练日不是今天或昨天，连续天数为0
  if (lastDate !== todayStr && lastDate !== yesterdayStr) {
    return 0;
  }

  // 从最后一天往前遍历
  for (let i = sortedDates.length - 1; i >= 0; i--) {
    if (i === sortedDates.length - 1) {
      streak = 1;
      continue;
    }
    const diff = daysBetween(sortedDates[i], sortedDates[i + 1]);
    if (diff === 1) {
      streak++;
    } else {
      break;
    }
  }

  return streak;
}

function dateToStr(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

function daysBetween(a: string, b: string): number {
  const da = new Date(a);
  const db = new Date(b);
  return Math.round((db.getTime() - da.getTime()) / 86400000);
}

/** 计算所有动作的PR（1RM估算） */
function computeAllPrs(records: TrainingRecord[]): ExercisePR[] {
  const exerciseData: Record<string, { weight: number; reps: number; date: string }[]> = {};

  for (const r of records) {
    for (const e of r.exercises) {
      if (!exerciseData[e.name]) {
        exerciseData[e.name] = [];
      }
      for (const s of e.sets) {
        if (s.weight > 0 && s.reps > 0) {
          exerciseData[e.name].push({
            weight: s.weight,
            reps: s.reps,
            date: r.date
          });
        }
      }
    }
  }

  const prs: ExercisePR[] = [];

  for (const [name, sets] of Object.entries(exerciseData)) {
    // 按Epley 1RM降序
    sets.sort((a, b) => estimateOneRm(b.weight, b.reps) - estimateOneRm(a.weight, a.reps));

    const best = sets[0];
    if (!best) continue;

    // 历史最高重量
    const maxWeightSet = sets.reduce((max, s) => s.weight > max.weight ? s : max, sets[0]);
    const estimatedOneRm = estimateOneRm(best.weight, best.reps);

    prs.push({
      exerciseName: name,
      estimatedOneRm: Math.round(estimatedOneRm),
      date: best.date,
      weight: best.weight,
      reps: best.reps,
      maxWeight: maxWeightSet.weight,
      maxWeightDate: maxWeightSet.date
    });
  }

  // 按1RM降序排序
  prs.sort((a, b) => b.estimatedOneRm - a.estimatedOneRm);

  return prs;
}

/** 计算近4周周训练量 */
function computeRecentWeeklyVolumes(records: TrainingRecord[]): WeeklyVolume[] {
  const now = new Date();
  const weeks: WeeklyVolume[] = [];

  for (let w = 0; w < 4; w++) {
    const weekEnd = new Date(now.getTime() - w * 7 * 86400000);
    const weekStartDate = new Date(weekEnd.getTime() - 6 * 86400000);
    const weekStart = dateToStr(weekStartDate);
    const weekEndStr = dateToStr(weekEnd);

    let totalSessions = 0;
    let totalSets = 0;
    let totalVolume = 0;

    for (const r of records) {
      if (r.date >= weekStart && r.date <= weekEndStr) {
        totalSessions++;
        for (const e of r.exercises) {
          for (const s of e.sets) {
            totalSets++;
            totalVolume += s.weight * s.reps;
          }
        }
      }
    }

    weeks.push({
      weekStart,
      totalSessions,
      totalSets,
      totalVolume: Math.round(totalVolume)
    });
  }

  return weeks;
}

/** 获取某动作的所有历史数据（用于图表） */
export function getExerciseHistory(records: TrainingRecord[], exerciseName: string): {
  date: string;
  maxWeight: number;
  maxOneRm: number;
  totalVolume: number;
}[] {
  const data: { date: string; maxWeight: number; maxOneRm: number; totalVolume: number }[] = [];

  for (const r of records) {
    for (const e of r.exercises) {
      if (e.name === exerciseName) {
        let maxWeight = 0;
        let bestOneRm = 0;
        let totalVolume = 0;

        for (const s of e.sets) {
          totalVolume += s.weight * s.reps;
          if (s.weight > maxWeight) maxWeight = s.weight;
          const rm = estimateOneRm(s.weight, s.reps);
          if (rm > bestOneRm) bestOneRm = rm;
        }

        data.push({
          date: r.date,
          maxWeight,
          maxOneRm: Math.round(bestOneRm),
          totalVolume
        });
      }
    }
  }

  // 按日期排序
  data.sort((a, b) => a.date.localeCompare(b.date));
  return data;
}

/** 获取所有不重复的动作名称列表（按出现频次排序） */
export function getAllExerciseNames(records: TrainingRecord[]): string[] {
  const counts: Record<string, number> = {};

  for (const r of records) {
    for (const e of r.exercises) {
      counts[e.name] = (counts[e.name] || 0) + 1;
    }
  }

  return Object.entries(counts)
    .sort((a, b) => b[1] - a[1])
    .map(([name]) => name);
}

/** 按日期分组训练记录 */
export function groupRecordsByDate(records: TrainingRecord[]): Map<string, TrainingRecord[]> {
  const map = new Map<string, TrainingRecord[]>();

  for (const r of records) {
    const existing = map.get(r.date);
    if (existing) {
      existing.push(r);
    } else {
      map.set(r.date, [r]);
    }
  }

  return map;
}
