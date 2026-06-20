/**
 * 仪表盘统计模型
 */

import { TrainingRecord, Exercise } from './TrainingRecord';

/** 单动作个人纪录 */
export interface ExercisePR {
  /** 动作名称 */
  exerciseName: string;
  /** 1RM估算值（kg），使用Epley公式 */
  estimatedOneRm: number;
  /** 该1RM对应的日期 */
  date: string;
  /** 该1RM对应的原始重量 */
  weight: number;
  /** 该1RM对应的次数 */
  reps: number;
  /** 历史最高重量（kg） */
  maxWeight: number;
  /** 历史最高重量日期 */
  maxWeightDate: string;
}

/** 周训练量统计 */
export interface WeeklyVolume {
  /** 周起始日 YYYY-MM-DD */
  weekStart: string;
  /** 周训练总次数 */
  totalSessions: number;
  /** 周总组数 */
  totalSets: number;
  /** 周总吨数（kg） */
  totalVolume: number;
}

/** 月度训练统计 */
export interface MonthlyStats {
  year: number;
  month: number;
  totalSessions: number;
  totalVolume: number;
  totalDuration: number;
}

/** 仪表盘聚合统计 */
export interface DashboardStats {
  /** 累计训练天数 */
  totalTrainingDays: number;
  /** 累计训练次数（会话数） */
  totalSessions: number;
  /** 累计总组数 */
  totalSets: number;
  /** 累计总吨数（kg） */
  totalVolume: number;
  /** 累计总训练时长（分钟） */
  totalDurationMinutes: number;
  /** 当前连续训练天数 */
  streakDays: number;
  /** 三大项1RM */
  bigThreePRs: ExercisePR[];
  /** 全部动作PR */
  allPRs: ExercisePR[];
  /** 近4周周训练量 */
  recentWeeklyVolumes: WeeklyVolume[];
}

/** 空仪表盘统计初始值 */
export const EMPTY_DASHBOARD_STATS: DashboardStats = {
  totalTrainingDays: 0,
  totalSessions: 0,
  totalSets: 0,
  totalVolume: 0,
  totalDurationMinutes: 0,
  streakDays: 0,
  bigThreePRs: [],
  allPRs: [],
  recentWeeklyVolumes: []
};
