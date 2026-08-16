import { preferences } from '@kit.ArkData';
import { describe, it, expect } from '@ohos/hypium';
import {
  PreferencesBackend,
  PreferencesStore
} from '../main/ets/data/PreferencesStore';
import { MenstrualDay } from '../main/ets/domain/MenstrualData';

class FakePreferencesBackend implements PreferencesBackend {
  readonly values: Map<string, preferences.ValueType> = new Map<string, preferences.ValueType>();
  failGet: boolean = false;
  failPut: boolean = false;
  failFlush: boolean = false;
  flushCount: number = 0;

  async get(key: string, defaultValue: preferences.ValueType): Promise<preferences.ValueType> {
    if (this.failGet) {
      throw new Error('get failed');
    }
    const value: preferences.ValueType | undefined = this.values.get(key);
    return value === undefined ? defaultValue : value;
  }

  async put(key: string, value: preferences.ValueType): Promise<void> {
    if (this.failPut) {
      throw new Error('put failed');
    }
    this.values.set(key, value);
  }

  async flush(): Promise<void> {
    this.flushCount += 1;
    if (this.failFlush) {
      throw new Error('flush failed');
    }
  }
}

export default function preferencesStoreTest() {
  describe('PreferencesStore', () => {
    it('reports unavailable storage without changing the fallback values', 0, async (): Promise<void> => {
      const store: PreferencesStore = PreferencesStore.fromBackend(undefined);
      const days = await store.loadDays();
      const welcome = await store.hasSeenWelcome();
      const write = await store.saveDays([]);

      expect(days.status).assertEqual('unavailable');
      expect(days.days).assertDeepEquals([]);
      expect(welcome.status).assertEqual('unavailable');
      expect(welcome.seen).assertFalse();
      expect(write.status).assertEqual('unavailable');
    });

    it('reports corrupted stored days as a failed read with empty days', 0, async (): Promise<void> => {
      const backend = new FakePreferencesBackend();
      backend.values.set('menstrual-days', 'not-json');
      const result = await PreferencesStore.fromBackend(backend).loadDays();

      expect(result.status).assertEqual('failed');
      expect(result.days).assertDeepEquals([]);
    });

    it('normalizes days before a successful write', 0, async (): Promise<void> => {
      const backend = new FakePreferencesBackend();
      const days: Array<MenstrualDay> = [
        { date: '2026-08-14', source: 'import' },
        { date: 'not-a-date', source: 'manual' },
        { date: '2026-08-14', source: 'manual' },
        { date: '2026-08-10', source: 'manual' }
      ];
      const result = await PreferencesStore.fromBackend(backend).saveDays(days);

      expect(result.status).assertEqual('success');
      expect(backend.flushCount).assertEqual(1);
      expect(backend.values.get('menstrual-days')).assertEqual(JSON.stringify([
        { date: '2026-08-10', source: 'manual' },
        { date: '2026-08-14', source: 'manual' }
      ]));
    });

    it('reports get failures for both date and welcome reads', 0, async (): Promise<void> => {
      const backend = new FakePreferencesBackend();
      backend.failGet = true;
      const store = PreferencesStore.fromBackend(backend);
      const days = await store.loadDays();
      const welcome = await store.hasSeenWelcome();

      expect(days.status).assertEqual('failed');
      expect(welcome.status).assertEqual('failed');
      expect(welcome.seen).assertFalse();
    });

    it('reports put and flush failures without throwing to the caller', 0, async (): Promise<void> => {
      const putFailureBackend = new FakePreferencesBackend();
      putFailureBackend.failPut = true;
      const putFailureStore = PreferencesStore.fromBackend(putFailureBackend);
      expect((await putFailureStore.saveDays([])).status).assertEqual('failed');
      expect((await putFailureStore.markWelcomeShown()).status).assertEqual('failed');

      const flushFailureBackend = new FakePreferencesBackend();
      flushFailureBackend.failFlush = true;
      const flushFailureStore = PreferencesStore.fromBackend(flushFailureBackend);
      expect((await flushFailureStore.saveDays([])).status).assertEqual('failed');
      expect((await flushFailureStore.markWelcomeShown()).status).assertEqual('failed');
    });

    it('returns success for a readable welcome marker and successful write', 0, async (): Promise<void> => {
      const backend = new FakePreferencesBackend();
      backend.values.set('welcome-shown', true);
      const store = PreferencesStore.fromBackend(backend);
      const read = await store.hasSeenWelcome();
      const write = await store.markWelcomeShown();

      expect(read.status).assertEqual('success');
      expect(read.seen).assertTrue();
      expect(write.status).assertEqual('success');
    });

  });
}
