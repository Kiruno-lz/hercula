import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { MenstrualDay, normalizeDays } from '../domain/MenstrualData';

const STORE_NAME: string = 'hercula-local-data';
const DAYS_KEY: string = 'menstrual-days';

export class PreferencesStore {
  private preferencesData: preferences.Preferences | undefined;

  private constructor(context: Context) {
  }

  static async open(context: Context): Promise<PreferencesStore> {
    const store: PreferencesStore = new PreferencesStore(context);
    store.preferencesData = await preferences.getPreferences(context, { name: STORE_NAME });
    return store;
  }

  async loadDays(): Promise<Array<MenstrualDay>> {
    if (this.preferencesData === undefined) {
      return [];
    }
    const raw: string = await this.preferencesData.get(DAYS_KEY, '[]') as string;
    try {
      const parsed: Array<MenstrualDay> = JSON.parse(raw) as Array<MenstrualDay>;
      return normalizeDays(parsed);
    } catch (_error) {
      return [];
    }
  }

  async saveDays(days: Array<MenstrualDay>): Promise<void> {
    if (this.preferencesData === undefined) {
      return;
    }
    await this.preferencesData.put(DAYS_KEY, JSON.stringify(normalizeDays(days)));
    await this.preferencesData.flush();
  }
}
