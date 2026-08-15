import { isValidDateKey } from './DateUtils';

export interface ImportValidationInput {
  dates: Array<string>;
  invalidTokens: Array<string>;
  duplicateDates: Array<string>;
  existingDates: Array<string>;
  today: string;
}

export interface ImportValidationResult {
  candidateDates: Array<string>;
  validDates: Array<string>;
  futureDates: Array<string>;
  duplicateDates: Array<string>;
  existingDates: Array<string>;
  invalidTokens: Array<string>;
}

function unique(values: Array<string>): Array<string> {
  const result: Array<string> = [];
  values.forEach((value: string): void => {
    if (!result.includes(value)) {
      result.push(value);
    }
  });
  return result;
}

export function validateImportDates(input: ImportValidationInput): ImportValidationResult {
  const invalidTokens: Array<string> = unique(input.invalidTokens);
  const candidateDates: Array<string> = [];
  input.dates.forEach((date: string): void => {
    if (isValidDateKey(date)) {
      if (!candidateDates.includes(date)) {
        candidateDates.push(date);
      }
    } else if (!invalidTokens.includes(date)) {
      invalidTokens.push(date);
    }
  });

  const futureDates: Array<string> = candidateDates.filter((date: string): boolean => date > input.today);
  const existingSet: Set<string> = new Set<string>(input.existingDates);
  const existingDates: Array<string> = candidateDates.filter((date: string): boolean => {
    return !futureDates.includes(date) && existingSet.has(date);
  });
  const duplicateDates: Array<string> = unique(input.duplicateDates);
  const validDates: Array<string> = candidateDates.filter((date: string): boolean => {
    return !futureDates.includes(date) && !existingDates.includes(date);
  });

  return {
    candidateDates,
    validDates,
    futureDates,
    duplicateDates,
    existingDates,
    invalidTokens
  };
}
