export function pad2(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}

export function toDateKey(date: Date): string {
  return `${date.getFullYear()}-${pad2(date.getMonth() + 1)}-${pad2(date.getDate())}`;
}

export function todayKey(): string {
  return toDateKey(new Date());
}

export function parseDateKey(value: string): Date {
  const parts: Array<string> = value.split('-');
  return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
}

export function addDays(value: string, amount: number): string {
  const date: Date = parseDateKey(value);
  date.setDate(date.getDate() + amount);
  return toDateKey(date);
}

export function dayDistance(from: string, to: string): number {
  const millisecondsPerDay: number = 24 * 60 * 60 * 1000;
  return Math.round((parseDateKey(to).getTime() - parseDateKey(from).getTime()) / millisecondsPerDay);
}

export function isValidDateKey(value: string): boolean {
  const match: RegExpMatchArray | null = value.match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (match === null) {
    return false;
  }
  const date: Date = parseDateKey(value);
  return date.getFullYear() === Number(match[1]) &&
    date.getMonth() + 1 === Number(match[2]) &&
    date.getDate() === Number(match[3]);
}

export function formatShortDate(value: string): string {
  const parts: Array<string> = value.split('-');
  return `${Number(parts[1])}月${Number(parts[2])}日`;
}
