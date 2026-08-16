import { MenstrualDay } from './MenstrualData';
import { DateCandidateResult, ImportIssues, mergeImportIssues } from './ImportTypes';
import { parseTextDates } from './TextDateParser';
import { ImportValidationResult, validateImportDates } from './ImportValidator';

export interface TextImportInput {
  text: string;
  jsonIssues: ImportIssues;
  existingDates: Array<string>;
  today: string;
  currentYear: number;
}

export function validateTextImport(input: TextImportInput): ImportValidationResult {
  const parsed: DateCandidateResult = parseTextDates(input.text, input.currentYear);
  const textIssues: ImportIssues = {
    invalidTokens: parsed.invalidTokens,
    duplicateDates: parsed.duplicateDates
  };
  const issues: ImportIssues = mergeImportIssues(textIssues, input.jsonIssues);
  return validateImportDates({
    dates: parsed.dates,
    invalidTokens: issues.invalidTokens,
    duplicateDates: issues.duplicateDates,
    existingDates: input.existingDates,
    today: input.today
  });
}

export function createImportedDays(validDates: Array<string>): Array<MenstrualDay> {
  return validDates.map((date: string): MenstrualDay => {
    return { date: date, source: 'import' };
  });
}
