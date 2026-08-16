export interface DateCandidateResult {
  dates: Array<string>;
  invalidTokens: Array<string>;
  duplicateDates: Array<string>;
}

export interface ImportIssues {
  invalidTokens: Array<string>;
  duplicateDates: Array<string>;
}

export function mergeImportIssues(current: ImportIssues, previous: ImportIssues): ImportIssues {
  return {
    invalidTokens: current.invalidTokens.concat(previous.invalidTokens),
    duplicateDates: current.duplicateDates.concat(previous.duplicateDates)
  };
}
