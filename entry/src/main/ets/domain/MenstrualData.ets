import { addDays, dayDistance, isValidDateKey, parseDateKey } from './DateUtils';

export interface MenstrualDay {
  date: string;
  source: 'manual' | 'import';
}

export interface PeriodSummary {
  startDate: string;
  endDate: string;
  durationDays: number;
  ongoing: boolean;
}

export interface Prediction {
  label: string;
  available: boolean;
}

export function normalizeDays(days: Array<MenstrualDay>): Array<MenstrualDay> {
  const byDate: Map<string, MenstrualDay> = new Map<string, MenstrualDay>();
  days.forEach((item: MenstrualDay) => {
    if (isValidDateKey(item.date)) {
      byDate.set(item.date, item);
    }
  });
  const dates: Array<string> = Array.from(byDate.keys()).sort();
  return dates.map((date: string): MenstrualDay => {
    return byDate.get(date) as MenstrualDay;
  });
}

export function derivePeriods(days: Array<MenstrualDay>, today: string): Array<PeriodSummary> {
  const normalizedDates: Array<string> = normalizeDays(days)
    .map((item: MenstrualDay): string => item.date)
    .filter((date: string): boolean => date <= today);
  const result: Array<PeriodSummary> = [];
  normalizedDates.forEach((startDate: string, index: number) => {
    const nextDate: string | undefined = normalizedDates[index + 1];
    const ongoing: boolean = nextDate === undefined;
    const endDate: string = ongoing ? today : addDays(nextDate, -1);
    const durationDays: number = ongoing
      ? dayDistance(startDate, today)
      : dayDistance(startDate, nextDate);
    result.push({
      startDate: startDate,
      endDate: endDate,
      durationDays: Math.max(1, durationDays),
      ongoing: ongoing
    });
  });
  return result;
}

export function predictNextPeriod(periods: Array<PeriodSummary>): Prediction {
  const completed: Array<PeriodSummary> = periods.filter((period: PeriodSummary): boolean => !period.ongoing);
  if (completed.length < 3) {
    return { available: false, label: '记录更多完整周期后显示估算' };
  }
  const cycleLengths: Array<number> = [];
  for (let index: number = 1; index < completed.length; index += 1) {
    cycleLengths.push(dayDistance(completed[index - 1].startDate, completed[index].startDate));
  }
  if (cycleLengths.length < 2) {
    return { available: false, label: '记录更多完整周期后显示估算' };
  }
  const sorted: Array<number> = cycleLengths.sort((a: number, b: number): number => a - b);
  const median: number = sorted[Math.floor(sorted.length / 2)];
  const last: PeriodSummary = completed[completed.length - 1];
  const predicted: string = addDays(last.startDate, median);
  const date: Date = parseDateKey(predicted);
  return {
    available: true,
    label: `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日左右`
  };
}
