import { common } from '@kit.AbilityKit';
import { fileIo as fs, picker, ReadOptions } from '@kit.CoreFileKit';
import { buffer } from '@kit.ArkTS';
import { isValidDateKey } from '../domain/DateUtils';
import { MenstrualDay, normalizeDays } from '../domain/MenstrualData';
import { todayKey } from '../domain/DateUtils';

const SCHEMA_VERSION: number = 1;
const MAX_IMPORT_BYTES: number = 4 * 1024 * 1024;

export interface HerculaExportFile {
  schemaVersion: number;
  exportedAt: string;
  days: Array<MenstrualDay>;
}

export interface JsonDateCandidateResult {
  dates: Array<string>;
  invalidTokens: Array<string>;
  duplicateDates: Array<string>;
}

export class JsonImportResult {
  readonly days: Array<MenstrualDay>;
  readonly invalidTokens: Array<string>;
  readonly duplicateDates: Array<string>;

  constructor(days: Array<MenstrualDay>, invalidTokens: Array<string> = [], duplicateDates: Array<string> = []) {
    this.days = days;
    this.invalidTokens = invalidTokens;
    this.duplicateDates = duplicateDates;
  }
}

function isObject(value: Object | null): boolean {
  return value !== null && typeof value === 'object';
}

function appendUnique(values: Array<string>, value: string): void {
  if (!values.includes(value)) {
    values.push(value);
  }
}

export function parseJsonDateCandidates(text: string): JsonDateCandidateResult {
  let parsed: Object;
  try {
    parsed = JSON.parse(text) as Object;
  } catch (_error) {
    throw new Error('JSON 格式无效');
  }
  if (!isObject(parsed)) {
    throw new Error('JSON 根节点必须是对象');
  }

  const payload = parsed as Record<string, Object>;
  if (payload.schemaVersion !== 1) {
    throw new Error('不支持的 JSON schema 版本');
  }
  if (typeof payload.exportedAt !== 'string' || payload.exportedAt.length === 0 ||
    isNaN(new Date(payload.exportedAt).getTime())) {
    throw new Error('缺少有效的 exportedAt');
  }
  if (!Array.isArray(payload.days)) {
    throw new Error('缺少有效的 days 数组');
  }

  const dates: Array<string> = [];
  const invalidTokens: Array<string> = [];
  const duplicateDates: Array<string> = [];
  const entries: Array<Object> = payload.days as Array<Object>;
  entries.forEach((entry: Object): void => {
    if (!isObject(entry)) {
      appendUnique(invalidTokens, '无法识别的日期条目');
      return;
    }
    const item = entry as Record<string, Object>;
    const rawDate: string = item.date as string;
    const source: string = item.source as string;
    if (typeof rawDate !== 'string' || (source !== 'manual' && source !== 'import')) {
      appendUnique(invalidTokens, typeof rawDate === 'string' ? rawDate : '缺少日期字段');
      return;
    }
    if (!isValidDateKey(rawDate)) {
      appendUnique(invalidTokens, rawDate);
      return;
    }
    if (dates.includes(rawDate)) {
      appendUnique(duplicateDates, rawDate);
    } else {
      dates.push(rawDate);
    }
  });
  return { dates, invalidTokens, duplicateDates };
}

export class JsonTransfer {
  static async export(context: common.UIAbilityContext, days: Array<MenstrualDay>): Promise<boolean> {
    const saveOptions = new picker.DocumentSaveOptions();
    saveOptions.newFileNames = [`hercula-${todayKey()}.json`];
    saveOptions.fileSuffixChoices = ['JSON|.json'];
    const pickerInstance = new picker.DocumentViewPicker(context);
    const uris: Array<string> = await pickerInstance.save(saveOptions);
    if (uris.length === 0) {
      return false;
    }

    const payload: HerculaExportFile = {
      schemaVersion: SCHEMA_VERSION,
      exportedAt: new Date().toISOString(),
      days: normalizeDays(days)
    };
    const file = fs.openSync(uris[0], fs.OpenMode.READ_WRITE);
    try {
      fs.writeSync(file.fd, JSON.stringify(payload));
    } finally {
      fs.closeSync(file);
    }
    return true;
  }

  static async import(context: common.UIAbilityContext): Promise<JsonImportResult | undefined> {
    const candidates: JsonDateCandidateResult | undefined = await JsonTransfer.selectDateCandidates(context);
    if (candidates === undefined) {
      return undefined;
    }
    const importedDays: Array<MenstrualDay> = candidates.dates.map((date: string): MenstrualDay => {
      return { date: date, source: 'import' };
    });
    return new JsonImportResult(normalizeDays(importedDays), candidates.invalidTokens, candidates.duplicateDates);
  }

  static async selectDateCandidates(context: common.UIAbilityContext): Promise<JsonDateCandidateResult | undefined> {
    const selectOptions = new picker.DocumentSelectOptions();
    selectOptions.maxSelectNumber = 1;
    selectOptions.fileSuffixFilters = ['.json'];
    const pickerInstance = new picker.DocumentViewPicker(context);
    const uris: Array<string> = await pickerInstance.select(selectOptions);
    if (uris.length === 0) {
      return undefined;
    }

    const text: string | undefined = JsonTransfer.readText(uris[0]);
    if (text === undefined) {
      return undefined;
    }
    return parseJsonDateCandidates(text);
  }

  private static readText(uri: string): string | undefined {
    const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
    try {
      const fileSize: number = fs.statSync(file.fd).size;
      if (fileSize <= 0 || fileSize > MAX_IMPORT_BYTES) {
        return undefined;
      }
      const arrayBuffer = new ArrayBuffer(fileSize);
      const options: ReadOptions = { offset: 0, length: fileSize };
      const readLength: number = fs.readSync(file.fd, arrayBuffer, options);
      return buffer.from(arrayBuffer, 0, readLength).toString('utf-8');
    } finally {
      fs.closeSync(file);
    }
  }
}
