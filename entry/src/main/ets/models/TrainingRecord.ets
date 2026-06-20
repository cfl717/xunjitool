/**
 * 训练记录核心数据模型
 * 对应训记导出CSV的4种记录类型
 */

/** 训练记录类型枚举 */
export enum TrainingType {
  /** 力量训练：包含动作、组数、重量、次数 */
  STRENGTH = 'strength',
  /** 有氧训练：距离、热量、心率 */
  CARDIO = 'cardio',
  /** Apple Health 训练：热量 */
  APPLE_HEALTH = 'apple_health',
  /** 最小记录：缺少train_time等字段 */
  MINIMAL = 'minimal'
}

/** 单次训练中的一组数据 */
export interface ExerciseSet {
  /** 组序号 */
  setNumber: number;
  /** 重量（kg），已统一归一化 */
  weight: number;
  /** 次数 */
  reps: number;
  /** 组耗时（秒），可能为0 */
  durationSeconds: number;
  /** 原始字符串，如"20kg"、"12次" */
  rawWeight: string;
  rawReps: string;
}

/** 训练中的单个动作 */
export interface Exercise {
  /** 动作序号（如 1.深蹲 → 1） */
  number: number;
  /** 动作名称 */
  name: string;
  /** 所有组 */
  sets: ExerciseSet[];
  /** 该动作总组数 */
  totalSets: number;
}

/** 一次训练记录（一次完整训练课） */
export interface TrainingRecord {
  /** 日期字符串 YYYY-MM-DD */
  date: string;
  /** 原始YYMMDD */
  rawDate: string;
  /** 训练会话唯一ID */
  id: string;
  /** 训练名称/标题 */
  name: string;
  /** 训练开始时间戳（毫秒） */
  startTime: number;
  /** 训练结束时间戳（毫秒） */
  endTime: number;
  /** 训练时长（分钟） */
  durationMinutes: number;
  /** 记录类型 */
  type: TrainingType;
  /** 训练中的动作列表（仅力量训练有） */
  exercises: Exercise[];
  /** 有氧/Apple Health：距离（米） */
  distance?: number;
  /** 有氧/Apple Health：热量（kcal） */
  calories?: number;
  /** 有氧：平均心率（bpm） */
  avgHeartRate?: number;
  /** 备注/元数据 */
  notes: string;
  /** 原始CSV字符串 */
  raw: string;
}

/** 动作名称标准化映射（不同写法归一化） */
export const EXERCISE_NAME_ALIASES: Record<string, string> = {
  '杠铃卧推': '杠铃卧推',
  '哑铃卧推': '哑铃卧推',
  '深蹲': '深蹲',
  '硬拉': '硬拉',
  '杠铃划船': '杠铃划船',
  '俯卧哑铃划船': '俯卧哑铃划船',
  '哑铃推肩': '哑铃推肩',
  '站姿杠铃推举': '站姿杠铃推举',
  '宽距下拉': '宽距下拉',
  '引体向上（辅助）': '引体向上（辅助）',
  '引体向上': '引体向上',
  '哑铃箭步蹲': '哑铃箭步蹲',
  '上斜哑铃飞鸟': '上斜哑铃飞鸟',
  '派克俯卧撑': '派克俯卧撑'
};

/** 三大项动作名称 */
export const BIG_THREE_EXERCISES: string[] = ['深蹲', '杠铃卧推', '硬拉'];

/**
 * 通过原始CSV记录判断训练类型
 */
export function detectTrainingType(rawCsv: string): TrainingType {
  if (rawCsv.includes('有氧训练')) {
    return TrainingType.CARDIO;
  }
  if (rawCsv.includes('苹果健康训练')) {
    return TrainingType.APPLE_HEALTH;
  }
  // 力量训练一般有动作组（N.动作名 模式）
  const hasExercises = /\d+\.\S+/.test(rawCsv);
  if (hasExercises) {
    return TrainingType.STRENGTH;
  }
  return TrainingType.MINIMAL;
}
