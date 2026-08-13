import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { MenstrualDay, normalizeDays } from '../domain/MenstrualData';

const STORE_NAME: string = 'hercula-local-data';
const DAYS_KEY: string = 'menstrual-days';
const WELCOME_KEY: string = 'welcome-shown';

export class PreferencesStore {
  private preferencesData: preferences.Preferences | undefined;

  private constructor() {
  }

  static async open(context: common.UIAbilityContext): Promise<PreferencesStore> {
    const store: PreferencesStore = new PreferencesStore();
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

  async hasSeenWelcome(): Promise<boolean> {
    if (this.preferencesData === undefined) {
      return false;
    }
    return await this.preferencesData.get(WELCOME_KEY, false) as boolean;
  }

  async markWelcomeShown(): Promise<void> {
    if (this.preferencesData === undefined) {
      return;
    }
    await this.preferencesData.put(WELCOME_KEY, true);
    await this.preferencesData.flush();
  }
}
