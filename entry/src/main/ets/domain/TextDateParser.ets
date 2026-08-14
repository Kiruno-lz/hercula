import { isValidDateKey, pad2 } from './DateUtils';

export interface TextDateParseResult {
  dates: Array<string>;
  invalidTokens: Array<string>;
}

const DATE_EXPRESSION: RegExp = /(\d{4})([-/.])(\d{1,2})([-/.])(\d{1,2})|(\d{4})年(\d{1,2})月(\d{1,2})日/g;
const TOKEN_SEPARATOR: RegExp = /[\s,，、;；|]+/;

function containsDigit(value: string): boolean {
  return /\d/.test(value);
}

function appendUnique(values: Array<string>, value: string): void {
  if (!values.includes(value)) {
    values.push(value);
  }
}

function dateKey(year: string, month: string, day: string): string {
  return `${year}-${pad2(Number(month))}-${pad2(Number(day))}`;
}

function parseToken(token: string, dates: Array<string>, invalidTokens: Array<string>): void {
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
        parsed = dateKey(match[1], match[3], match[5]);
      }
    } else {
      parsed = dateKey(match[6], match[7], match[8]);
    }

    if (parsed.length > 0) {
      if (isValidDateKey(parsed)) {
        appendUnique(dates, parsed);
      } else {
        appendUnique(invalidTokens, raw);
      }
    }
    match = DATE_EXPRESSION.exec(trimmed);
  }
  DATE_EXPRESSION.lastIndex = 0;

  if (!foundExpression && containsDigit(trimmed)) {
    appendUnique(invalidTokens, trimmed);
  }
}

export function parseTextDates(input: string): TextDateParseResult {
  const dates: Array<string> = [];
  const invalidTokens: Array<string> = [];
  input.split(TOKEN_SEPARATOR).forEach((token: string): void => {
    parseToken(token, dates, invalidTokens);
  });
  return { dates, invalidTokens };
}
