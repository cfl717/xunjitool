/**
 * 训记 API 接口服务
 * 从训记服务端获取最新训练数据
 */

import { TrainingRecord } from '../models/TrainingRecord';
import { parseAllRecords } from './DataParser';

// 训记API基础配置
const TRAINS_API = {
  BASE_URL: 'https://api.trains.com', // 实际API端点需替换
  TIMEOUT_MS: 30000
};

/** API返回的原始数据格式 */
interface ApiResponse {
  res: string[];
  _cached_at?: number;
  _datestr?: string;
  _api_success?: boolean;
}

/**
 * 获取指定日期的训练数据
 * @param dateStr YYYY-MM-DD 格式日期
 */
export async function fetchDay(dateStr: string): Promise<TrainingRecord[]> {
  try {
    const response = await fetch(
      `${TRAINS_API.BASE_URL}/trains?date=${dateStr}`,
      {
        method: 'GET',
        headers: { 'Content-Type': 'application/json' },
        timeout: TRAINS_API.TIMEOUT_MS
      }
    );

    if (!response.ok) {
      console.warn(`TrainsApi: fetch ${dateStr} failed with ${response.status}`);
      return [];
    }

    const data: ApiResponse = await response.json();

    if (!data.res || !Array.isArray(data.res) || data.res.length === 0) {
      return [];
    }

    return parseAllRecords(data.res);
  } catch (err) {
    console.error(`TrainsApi: fetchDay(${dateStr}) error`, JSON.stringify(err));
    return [];
  }
}

/**
 * 批量获取多日数据
 */
export async function fetchDateRange(startDate: string, endDate: string): Promise<TrainingRecord[]> {
  const start = new Date(startDate);
  const end = new Date(endDate);
  const allRecords: TrainingRecord[] = [];

  const current = new Date(start);
  while (current <= end) {
    const dateStr = formatDate(current);
    const records = await fetchDay(dateStr);
    allRecords.push(...records);
    current.setDate(current.getDate() + 1);
  }

  return allRecords;
}

/** 获取最近N天数据 */
export async function fetchRecentDays(days: number = 30): Promise<TrainingRecord[]> {
  const end = new Date();
  const start = new Date(end.getTime() - days * 86400000);
  return fetchDateRange(formatDate(start), formatDate(end));
}

function formatDate(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}
