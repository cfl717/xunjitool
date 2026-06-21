import { TrainingRecord, TrainingType, Exercise, ExerciseSet, BIG_THREE_EXERCISES } from '../models/TrainingRecord';
import { DashboardStats, ExercisePR, WeeklyVolume, EMPTY_DASHBOARD_STATS } from '../models/DashboardStats';
import { estimateOneRm } from '../utils/EpleyFormula';

interface ExerciseEntry { weight: number; reps: number; date: string; }
interface HistoryEntry { date: string; maxWeight: number; maxOneRm: number; totalVolume: number; }

export function computeDashboardStats(records: TrainingRecord[]): DashboardStats {
  if (!records || records.length === 0) return EMPTY_DASHBOARD_STATS;
  const strengthRecords = records.filter((r: TrainingRecord) => r.type === TrainingType.STRENGTH);
  const allDates = new Set<string>(records.map((r: TrainingRecord) => r.date));
  let totalSets = 0;
  let totalVolume = 0;
  let totalDuration = 0;
  for (const r of records) {
    totalDuration += r.durationMinutes || 0;
    if (r.exercises) {
      for (const e of r.exercises) {
        for (const s of e.sets) { totalSets++; totalVolume += s.weight * s.reps; }
      }
    }
  }
  const sortedDates = Array.from(allDates).sort();
  const streakDays = computeStreak(sortedDates);
  const allPRs = computeAllPrs(strengthRecords);
  const bigThreePRs = allPRs.filter((pr: ExercisePR) => BIG_THREE_EXERCISES.includes(pr.exerciseName));
  const recentWeeklyVolumes = computeRecentWeeklyVolumes(records);
  return {
    totalTrainingDays: allDates.size, totalSessions: records.length,
    totalSets, totalVolume: Math.round(totalVolume), totalDurationMinutes: totalDuration,
    streakDays, bigThreePRs, allPRs, recentWeeklyVolumes
  };
}

function computeStreak(sortedDates: string[]): number {
  if (sortedDates.length === 0) return 0;
  const todayStr = dateToStr(new Date());
  const yesterdayStr = dateToStr(new Date(Date.now() - 86400000));
  const lastDate = sortedDates[sortedDates.length - 1];
  if (lastDate !== todayStr && lastDate !== yesterdayStr) return 0;
  let streak = 0;
  for (let i = sortedDates.length - 1; i >= 0; i--) {
    if (i === sortedDates.length - 1) { streak = 1; continue; }
    if (daysBetween(sortedDates[i], sortedDates[i + 1]) === 1) streak++;
    else break;
  }
  return streak;
}

function dateToStr(d: Date): string {
  return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
}

function daysBetween(a: string, b: string): number {
  return Math.round((new Date(b).getTime() - new Date(a).getTime()) / 86400000);
}

function computeAllPrs(records: TrainingRecord[]): ExercisePR[] {
  const data: Record<string, ExerciseEntry[]> = {};
  for (const r of records) {
    for (const e of r.exercises) {
      if (!data[e.name]) data[e.name] = [];
      for (const s of e.sets) {
        if (s.weight > 0 && s.reps > 0) data[e.name].push({ weight: s.weight, reps: s.reps, date: r.date });
      }
    }
  }
  const prs: ExercisePR[] = [];
  for (const name of Object.keys(data)) {
    const sets = data[name];
    sets.sort((a, b) => estimateOneRm(b.weight, b.reps) - estimateOneRm(a.weight, a.reps));
    const best = sets[0];
    if (!best) continue;
    const maxWeightSet = sets.reduce((max, s) => s.weight > max.weight ? s : max, sets[0]);
    prs.push({
      exerciseName: name,
      estimatedOneRm: Math.round(estimateOneRm(best.weight, best.reps)),
      date: best.date, weight: best.weight, reps: best.reps,
      maxWeight: maxWeightSet.weight, maxWeightDate: maxWeightSet.date
    });
  }
  prs.sort((a, b) => b.estimatedOneRm - a.estimatedOneRm);
  return prs;
}

function computeRecentWeeklyVolumes(records: TrainingRecord[]): WeeklyVolume[] {
  const now = new Date();
  const weeks: WeeklyVolume[] = [];
  // Initialize 4 weeks
  for (let w = 0; w < 4; w++) {
    const weekEnd = new Date(now.getTime() - w * 7 * 86400000);
    const weekStart = dateToStr(new Date(weekEnd.getTime() - 6 * 86400000));
    weeks.push({ weekStart: weekStart, totalSessions: 0, totalSets: 0, totalVolume: 0 });
  }
  // Single pass: categorize each record into its week
  for (const r of records) {
    for (let w = 0; w < 4; w++) {
      const ws = weeks[w].weekStart;
      const we = dateToStr(new Date(new Date(ws).getTime() + 6 * 86400000));
      if (r.date >= ws && r.date <= we) {
        weeks[w].totalSessions++;
        if (r.exercises) {
          for (const e of r.exercises) {
            for (const s of e.sets) { weeks[w].totalSets++; weeks[w].totalVolume += s.weight * s.reps; }
          }
        }
        break;
      }
    }
  }
  for (let w = 0; w < 4; w++) weeks[w].totalVolume = Math.round(weeks[w].totalVolume);
  return weeks;
}

export function getExerciseHistory(records: TrainingRecord[], exerciseName: string): HistoryEntry[] {
  const data: HistoryEntry[] = [];
  for (const r of records) {
    for (const e of r.exercises) {
      if (e.name === exerciseName) {
        let maxWeight = 0, bestOneRm = 0, totalVolume = 0;
        for (const s of e.sets) {
          totalVolume += s.weight * s.reps;
          if (s.weight > maxWeight) maxWeight = s.weight;
          const rm = estimateOneRm(s.weight, s.reps);
          if (rm > bestOneRm) bestOneRm = rm;
        }
        data.push({ date: r.date, maxWeight, maxOneRm: Math.round(bestOneRm), totalVolume });
      }
    }
  }
  data.sort((a, b) => a.date.localeCompare(b.date));
  return data;
}

export function getAllExerciseNames(records: TrainingRecord[]): string[] {
  const counts: Record<string, number> = {};
  for (const r of records) {
    for (const e of r.exercises) counts[e.name] = (counts[e.name] || 0) + 1;
  }
  return Object.entries(counts).sort((a, b) => b[1] - a[1]).map((pair) => pair[0]);
}

export function groupRecordsByDate(records: TrainingRecord[]): Map<string, TrainingRecord[]> {
  const map = new Map<string, TrainingRecord[]>();
  for (const r of records) {
    const existing = map.get(r.date);
    if (existing) { existing.push(r); }
    else { map.set(r.date, [r]); }
  }
  return map;
}
