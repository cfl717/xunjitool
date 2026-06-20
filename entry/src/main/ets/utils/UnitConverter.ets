/**
 * 单位转换工具
 */

/** 将重量字符串解析为kg数值 */
export function parseWeight(value: string, unit: string = 'kg'): number {
  const cleaned = value.replace(/\s+/g, '');
  const match = cleaned.match(/^([\d.]+)(kg|斤|lb|lbs)?$/i);
  if (!match) return 0;

  const num = parseFloat(match[1]);
  const rawUnit = (match[2] || unit).toLowerCase();

  switch (rawUnit) {
    case '斤':
      return num / 2; // 1斤 = 0.5kg
    case 'lb':
    case 'lbs':
      return num * 0.453592; // 1lb ≈ 0.4536kg
    case 'kg':
    default:
      return num;
  }
}

/** 格式化为带单位的重量字符串 */
export function formatWeight(kg: number, targetUnit: string = 'kg'): string {
  const value = targetUnit === 'lb' ? kg / 0.453592 : kg;
  return `${Math.round(value)}${targetUnit}`;
}
