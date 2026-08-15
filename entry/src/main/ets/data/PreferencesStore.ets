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
    try {
      store.preferencesData = await preferences.getPreferences(context, { name: STORE_NAME });
    } catch (_error) {
      store.preferencesData = undefined;
    }
    return store;
  }

  async loadDays(): Promise<Array<MenstrualDay>> {
    if (this.preferencesData === undefined) {
      return [];
    }
    try {
      const raw: string = await this.preferencesData.get(DAYS_KEY, '[]') as string;
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
    try {
      await this.preferencesData.put(DAYS_KEY, JSON.stringify(normalizeDays(days)));
      await this.preferencesData.flush();
    } catch (_error) {
      // Keep the in-memory state usable when local storage is unavailable.
    }
  }

  async hasSeenWelcome(): Promise<boolean> {
    if (this.preferencesData === undefined) {
      return false;
    }
    try {
      return await this.preferencesData.get(WELCOME_KEY, false) as boolean;
    } catch (_error) {
      return false;
    }
  }

  async markWelcomeShown(): Promise<void> {
    if (this.preferencesData === undefined) {
      return;
    }
    try {
      await this.preferencesData.put(WELCOME_KEY, true);
      await this.preferencesData.flush();
    } catch (_error) {
      // The welcome dialog may be shown again if the marker cannot be saved.
    }
  }
}
