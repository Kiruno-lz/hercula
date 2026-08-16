import { common } from '@kit.AbilityKit';
import { fileIo as fs, picker, ReadOptions } from '@kit.CoreFileKit';
import { buffer } from '@kit.ArkTS';
import { isValidDateKey, todayKey } from '../domain/DateUtils';
import { MenstrualDay, normalizeDays } from '../domain/MenstrualData';
import { DateCandidateResult } from '../domain/ImportTypes';

const SCHEMA_VERSION: number = 1;
const MAX_IMPORT_BYTES: number = 4 * 1024 * 1024;

export type JsonCandidateLoadStatus = 'success' | 'cancelled' | 'read-failed' | 'empty' | 'too-large';

export interface JsonCandidateLoadResult {
  status: JsonCandidateLoadStatus;
  candidates: DateCandidateResult | undefined;
}

type JsonFileReadStatus = 'success' | 'read-failed' | 'empty' | 'too-large';

interface JsonFileReadResult {
  status: JsonFileReadStatus;
  text: string | undefined;
}

interface HerculaExportFile {
  schemaVersion: number;
  exportedAt: string;
  days: Array<MenstrualDay>;
}

function isObject(value: Object | null): boolean {
  return value !== null && typeof value === 'object';
}

function appendUnique(values: Array<string>, value: string): void {
  if (!values.includes(value)) {
    values.push(value);
  }
}

export function classifyJsonFileSize(fileSize: number): JsonFileReadStatus {
  if (fileSize <= 0) {
    return 'empty';
  }
  if (fileSize > MAX_IMPORT_BYTES) {
    return 'too-large';
  }
  return 'success';
}

export function parseJsonDateCandidates(text: string): DateCandidateResult {
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
  static async export(context: common.UIAbilityContext, days: Array<MenstrualDay>): Promise<void> {
    const saveOptions = new picker.DocumentSaveOptions();
    saveOptions.newFileNames = [`hercula-${todayKey()}.json`];
    saveOptions.fileSuffixChoices = ['JSON|.json'];
    const pickerInstance = new picker.DocumentViewPicker(context);
    const uris: Array<string> = await pickerInstance.save(saveOptions);
    if (uris.length === 0) {
      return;
    }

    const payload: HerculaExportFile = {
      schemaVersion: SCHEMA_VERSION,
      exportedAt: new Date().toISOString(),
      days: normalizeDays(days)
    };
    let file: fs.File | undefined = undefined;
    try {
      file = fs.openSync(uris[0], fs.OpenMode.READ_WRITE);
      fs.writeSync(file.fd, JSON.stringify(payload));
    } catch (_error) {
    } finally {
      if (file !== undefined) {
        try {
          fs.closeSync(file);
        } catch (_closeError) {}
      }
    }
  }

  static async selectDateCandidates(context: common.UIAbilityContext): Promise<JsonCandidateLoadResult> {
    const selectOptions = new picker.DocumentSelectOptions();
    selectOptions.maxSelectNumber = 1;
    selectOptions.fileSuffixFilters = ['.json'];
    const pickerInstance = new picker.DocumentViewPicker(context);
    const uris: Array<string> = await pickerInstance.select(selectOptions);
    if (uris.length === 0) {
      return { status: 'cancelled', candidates: undefined };
    }

    const fileResult: JsonFileReadResult = JsonTransfer.readText(uris[0]);
    if (fileResult.status !== 'success' || fileResult.text === undefined) {
      return { status: fileResult.status, candidates: undefined };
    }
    return { status: 'success', candidates: parseJsonDateCandidates(fileResult.text) };
  }

  private static readText(uri: string): JsonFileReadResult {
    let file: fs.File | undefined = undefined;
    try {
      file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      const fileSize: number = fs.statSync(file.fd).size;
      const sizeStatus: JsonFileReadStatus = classifyJsonFileSize(fileSize);
      if (sizeStatus !== 'success') {
        return { status: sizeStatus, text: undefined };
      }
      const arrayBuffer = new ArrayBuffer(fileSize);
      const options: ReadOptions = { offset: 0, length: fileSize };
      const readLength: number = fs.readSync(file.fd, arrayBuffer, options);
      return { status: 'success', text: buffer.from(arrayBuffer, 0, readLength).toString('utf-8') };
    } catch (_error) {
      return { status: 'read-failed', text: undefined };
    } finally {
      if (file !== undefined) {
        try {
          fs.closeSync(file);
        } catch (_closeError) {}
      }
    }
  }
}
