import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { MenstrualDay, normalizeDays } from '../domain/MenstrualData';

const STORE_NAME: string = 'hercula-local-data';
const DAYS_KEY: string = 'menstrual-days';
const WELCOME_KEY: string = 'welcome-shown';

type PreferencesOperationStatus = 'success' | 'unavailable' | 'failed';

export interface PreferencesBackend {
  get(key: string, defaultValue: preferences.ValueType): Promise<preferences.ValueType>;
  put(key: string, value: preferences.ValueType): Promise<void>;
  flush(): Promise<void>;
}

interface PreferencesDaysLoadResult {
  status: PreferencesOperationStatus;
  days: Array<MenstrualDay>;
}

interface PreferencesWelcomeReadResult {
  status: PreferencesOperationStatus;
  seen: boolean;
}

interface PreferencesWriteResult {
  status: PreferencesOperationStatus;
}

class ArkDataPreferencesBackend implements PreferencesBackend {
  private readonly data: preferences.Preferences;

  constructor(data: preferences.Preferences) {
    this.data = data;
  }

  async get(key: string, defaultValue: preferences.ValueType): Promise<preferences.ValueType> {
    try {
      return await this.data.get(key, defaultValue);
    } catch (_error) {
      return Promise.reject(_error);
    }
  }

  async put(key: string, value: preferences.ValueType): Promise<void> {
    try {
      await this.data.put(key, value);
    } catch (_error) {
      return Promise.reject(_error);
    }
  }

  async flush(): Promise<void> {
    try {
      await this.data.flush();
    } catch (_error) {
      return Promise.reject(_error);
    }
  }
}

export class PreferencesStore {
  private readonly preferencesData: PreferencesBackend | undefined;

  private constructor(preferencesData: PreferencesBackend | undefined) {
    this.preferencesData = preferencesData;
  }

  static async open(context: common.UIAbilityContext): Promise<PreferencesStore> {
    try {
      const data: preferences.Preferences = await preferences.getPreferences(context, { name: STORE_NAME });
      return new PreferencesStore(new ArkDataPreferencesBackend(data));
    } catch (_error) {
      return new PreferencesStore(undefined);
    }
  }

  static fromBackend(backend: PreferencesBackend | undefined): PreferencesStore {
    return new PreferencesStore(backend);
  }

  async loadDays(): Promise<PreferencesDaysLoadResult> {
    if (this.preferencesData === undefined) {
      return { status: 'unavailable', days: [] };
    }
    try {
      const raw: string = await this.preferencesData.get(DAYS_KEY, '[]') as string;
      const parsed: Array<MenstrualDay> = JSON.parse(raw) as Array<MenstrualDay>;
      return { status: 'success', days: normalizeDays(parsed) };
    } catch (_error) {
      return { status: 'failed', days: [] };
    }
  }

  async saveDays(days: Array<MenstrualDay>): Promise<PreferencesWriteResult> {
    if (this.preferencesData === undefined) {
      return { status: 'unavailable' };
    }
    try {
      await this.preferencesData.put(DAYS_KEY, JSON.stringify(normalizeDays(days)));
      await this.preferencesData.flush();
      return { status: 'success' };
    } catch (_error) {
      return { status: 'failed' };
    }
  }

  async hasSeenWelcome(): Promise<PreferencesWelcomeReadResult> {
    if (this.preferencesData === undefined) {
      return { status: 'unavailable', seen: false };
    }
    try {
      return {
        status: 'success',
        seen: await this.preferencesData.get(WELCOME_KEY, false) as boolean
      };
    } catch (_error) {
      return { status: 'failed', seen: false };
    }
  }

  async markWelcomeShown(): Promise<PreferencesWriteResult> {
    if (this.preferencesData === undefined) {
      return { status: 'unavailable' };
    }
    try {
      await this.preferencesData.put(WELCOME_KEY, true);
      await this.preferencesData.flush();
      return { status: 'success' };
    } catch (_error) {
      return { status: 'failed' };
    }
  }
}
