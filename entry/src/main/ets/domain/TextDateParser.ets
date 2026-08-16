import { isValidDateKey, pad2 } from './DateUtils';
import { DateCandidateResult } from './ImportTypes';

const DATE_EXPRESSION: RegExp =
  /(\d{4}|\d{2})([-/.])(\d{1,2})([-/.])(\d{1,2})|(\d{4})年(\d{1,2})月(\d{1,2})日|(\d{2})年(\d{1,2})月(\d{1,2})日|(\d{1,2})([-/.])(\d{1,2})|(\d{1,2})月(\d{1,2})日/g;
const COMPACT_DATE_EXPRESSION: RegExp = /(^|[^\d年月日])(\d{8}|\d{6}|\d{4})(?=$|[^\d年月日])/g;
const TOKEN_SEPARATOR: RegExp = /[\s,，、;；|]+/;

function containsDigit(value: string): boolean {
  return /\d/.test(value);
}

function appendUnique(values: Array<string>, value: string): void {
  if (!values.includes(value)) {
    values.push(value);
  }
}

function normalizeYear(year: string): string {
  return year.length === 2 ? `${2000 + Number(year)}` : year;
}

function dateKey(year: string, month: string, day: string, fallbackYear: number): string {
  const normalizedYear: string = year.length === 0 ? `${fallbackYear}` : normalizeYear(year);
  return `${normalizedYear}-${pad2(Number(month))}-${pad2(Number(day))}`;
}

function appendParsedDate(raw: string, parsed: string, dates: Array<string>, invalidTokens: Array<string>,
  duplicateDates: Array<string>): void {
  if (isValidDateKey(parsed)) {
    if (dates.includes(parsed)) {
      appendUnique(duplicateDates, parsed);
    } else {
      dates.push(parsed);
    }
  } else {
    appendUnique(invalidTokens, raw);
  }
}

function parseToken(token: string, dates: Array<string>, invalidTokens: Array<string>, duplicateDates: Array<string>,
  fallbackYear: number): void {
  const trimmed: string = token.trim();
  if (trimmed.length === 0) {
    return;
  }

  let foundExpression: boolean = false;
  let match: RegExpExecArray | null = DATE_EXPRESSION.exec(trimmed);
  while (match !== null) {
    foundExpression = true;
    const raw: string = match[0];
    let parsed: string = '';
    if (match[1] !== undefined && match[1] !== '') {
      if (match[2] !== match[4]) {
        appendUnique(invalidTokens, raw);
      } else {
        parsed = dateKey(match[1], match[3], match[5], fallbackYear);
      }
    } else if (match[6] !== undefined && match[6] !== '') {
      parsed = dateKey(match[6], match[7], match[8], fallbackYear);
    } else if (match[9] !== undefined && match[9] !== '') {
      parsed = dateKey(match[9], match[10], match[11], fallbackYear);
    } else if (match[12] !== undefined && match[12] !== '') {
      parsed = dateKey('', match[12], match[14], fallbackYear);
    } else {
      parsed = dateKey('', match[15], match[16], fallbackYear);
    }

    if (parsed.length > 0) {
      appendParsedDate(raw, parsed, dates, invalidTokens, duplicateDates);
    }
    match = DATE_EXPRESSION.exec(trimmed);
  }
  DATE_EXPRESSION.lastIndex = 0;

  if (!foundExpression) {
    let compactMatch: RegExpExecArray | null = COMPACT_DATE_EXPRESSION.exec(trimmed);
    while (compactMatch !== null) {
      foundExpression = true;
      const compact: string = compactMatch[2];
      let parsed: string = '';
      if (compact.length === 8) {
        parsed = dateKey(compact.substring(0, 4), compact.substring(4, 6), compact.substring(6, 8), fallbackYear);
      } else if (compact.length === 6) {
        parsed = dateKey(compact.substring(0, 2), compact.substring(2, 4), compact.substring(4, 6), fallbackYear);
      } else {
        parsed = dateKey('', compact.substring(0, 2), compact.substring(2, 4), fallbackYear);
      }
      appendParsedDate(compact, parsed, dates, invalidTokens, duplicateDates);
      compactMatch = COMPACT_DATE_EXPRESSION.exec(trimmed);
    }
    COMPACT_DATE_EXPRESSION.lastIndex = 0;
  }

  if (!foundExpression && containsDigit(trimmed)) {
    appendUnique(invalidTokens, trimmed);
  }
}

export function parseTextDates(input: string, currentYear: number = new Date().getFullYear()): DateCandidateResult {
  const dates: Array<string> = [];
  const invalidTokens: Array<string> = [];
  const duplicateDates: Array<string> = [];
  input.split(TOKEN_SEPARATOR).forEach((token: string): void => {
    parseToken(token, dates, invalidTokens, duplicateDates, currentYear);
  });
  return { dates, invalidTokens, duplicateDates };
}
