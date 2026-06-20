/**
 * 日期工具
 */

/** YYMMDD → YYYY-MM-DD */
export function yymmddToDateStr(yymmdd: string): string {
  if (yymmdd.length !== 6) return yymmdd;
  const yy = parseInt(yymmdd.substring(0, 2));
  const mm = yymmdd.substring(2, 4);
  const dd = yymmdd.substring(4, 6);
  const yyyy = yy > 50 ? 1900 + yy : 2000 + yy;
  return `${yyyy}-${mm}-${dd}`;
}

/** YYYY-MM-DD → Date */
export function dateStrToDate(dateStr: string): Date {
  const parts = dateStr.split('-').map(Number);
  return new Date(parts[0], parts[1] - 1, parts[2]);
}

/** Date → YYYY-MM-DD */
export function dateToDateStr(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

/** 获取本周一的日期字符串 */
export function getWeekStart(date: Date = new Date()): string {
  const d = new Date(date);
  const day = d.getDay();
  const diff = d.getDate() - day + (day === 0 ? -6 : 1);
  d.setDate(diff);
  return dateToDateStr(d);
}

/** 计算两个日期之间的天数 */
export function daysBetween(a: string, b: string): number {
  const da = dateStrToDate(a);
  const db = dateStrToDate(b);
  return Math.round((db.getTime() - da.getTime()) / (86400000));
}

/** 格式化时间戳为可读时间 */
export function formatTimestamp(ts: number): string {
  const d = new Date(ts);
  const h = String(d.getHours()).padStart(2, '0');
  const m = String(d.getMinutes()).padStart(2, '0');
  return `${h}:${m}`;
}

/** 格式化训练时长 */
export function formatDuration(minutes: number): string {
  if (minutes < 60) return `${Math.round(minutes)}分`;
  const h = Math.floor(minutes / 60);
  const m = Math.round(minutes % 60);
  return m > 0 ? `${h}时${m}分` : `${h}时`;
}
