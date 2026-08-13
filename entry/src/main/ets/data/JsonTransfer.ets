import { common } from '@kit.AbilityKit';
import { fileIo as fs, picker, ReadOptions } from '@kit.CoreFileKit';
import { buffer } from '@kit.ArkTS';
import { MenstrualDay, normalizeDays } from '../domain/MenstrualData';
import { todayKey } from '../domain/DateUtils';

const SCHEMA_VERSION: number = 1;
const MAX_IMPORT_BYTES: number = 4 * 1024 * 1024;

export interface HerculaExportFile {
  schemaVersion: number;
  exportedAt: string;
  days: Array<MenstrualDay>;
}

export class JsonImportResult {
  readonly days: Array<MenstrualDay>;

  constructor(days: Array<MenstrualDay>) {
    this.days = days;
  }
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
    const selectOptions = new picker.DocumentSelectOptions();
    selectOptions.maxSelectNumber = 1;
    selectOptions.fileSuffixFilters = ['JSON|.json'];
    const pickerInstance = new picker.DocumentViewPicker(context);
    const uris: Array<string> = await pickerInstance.select(selectOptions);
    if (uris.length === 0) {
      return undefined;
    }

    const text: string | undefined = JsonTransfer.readText(uris[0]);
    if (text === undefined) {
      return undefined;
    }
    const payload = JSON.parse(text) as HerculaExportFile;
    if (payload.schemaVersion !== SCHEMA_VERSION || !Array.isArray(payload.days)) {
      return undefined;
    }
    const importedDays: Array<MenstrualDay> = payload.days.map((item: MenstrualDay): MenstrualDay => {
      return { date: item.date, source: 'import' };
    });
    return new JsonImportResult(normalizeDays(importedDays));
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
