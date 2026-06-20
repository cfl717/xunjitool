/**
 * Epley 公式 — 估算1RM（最大重复次数重量）
 *
 * 1RM = weight * (1 + reps / 30)
 * 适用范围：1~12次，超过12次精度下降
 */

/** 使用Epley公式估算1RM */
export function estimateOneRm(weight: number, reps: number): number {
  if (reps <= 0 || weight <= 0) return 0;
  if (reps === 1) return weight;
  // Epley: 1RM = w * (1 + r/30)
  return weight * (1 + reps / 30);
}

/** 根据目标次数推算训练重量（1RM的百分比） */
export function trainingWeightPercentage(reps: number): number {
  // 基于Epley反推
  return 1 / (1 + reps / 30);
}

/** 根据1RM和目标次数计算训练重量 */
export function calculateTrainingWeight(oneRm: number, targetReps: number): number {
  return oneRm * trainingWeightPercentage(targetReps);
}

/** 判断一组是否可能为PR（基于Epley估算） */
export function isPotentialPr(weight: number, reps: number, currentOneRm: number): boolean {
  if (currentOneRm <= 0) return true;
  const estimated = estimateOneRm(weight, reps);
  return estimated > currentOneRm * 1.01; // 超过当前1RM 1%即视为可能PR
}
