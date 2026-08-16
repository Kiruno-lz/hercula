import { describe, it, expect } from '@ohos/hypium';
import {
  buildCalendarCells,
  derivePeriods,
  MenstrualDay,
  normalizeDays,
  PeriodSummary,
  predictNextPeriod
} from '../main/ets/domain/MenstrualData';

export default function menstrualDataTest() {
  describe('MenstrualData', () => {
    it('uses the next chronological start when calculating cross-year durations', 0, () => {
      const days: Array<MenstrualDay> = [
        { date: '2025-05-10', source: 'import' },
        { date: '2025-05-13', source: 'import' },
        { date: '2025-05-28', source: 'import' },
        { date: '2026-05-03', source: 'import' },
        { date: '2026-05-10', source: 'import' }
      ];
      const periods = derivePeriods(days, '2026-08-10');
      expect(durationFor(periods, '2025-05-10')).assertEqual(3);
      expect(durationFor(periods, '2025-05-13')).assertEqual(15);
      expect(durationFor(periods, '2025-05-28')).assertEqual(340);
      expect(durationFor(periods, '2026-05-03')).assertEqual(7);
      expect(durationFor(periods, '2026-05-10')).assertEqual(92);
    });

    it('ends each historical period at the next saved date instead of today', 0, () => {
      const days: Array<MenstrualDay> = [
        { date: '2024-08-16', source: 'import' },
        { date: '2024-11-24', source: 'import' },
        { date: '2025-04-12', source: 'import' }
      ];
      const periods = derivePeriods(days, '2025-08-16');
      expect(durationFor(periods, '2024-08-16')).assertEqual(100);
      expect(durationFor(periods, '2024-11-24')).assertEqual(139);
      expect(durationFor(periods, '2025-04-12')).assertEqual(126);
    });

    it('sorts valid days and keeps the last record for a duplicate date', 0, () => {
      const days: Array<MenstrualDay> = [
        { date: '2026-08-14', source: 'import' },
        { date: 'not-a-date', source: 'manual' },
        { date: '2025-12-31', source: 'manual' },
        { date: '2026-08-14', source: 'manual' }
      ];
      expect(normalizeDays(days)).assertDeepEquals([
        { date: '2025-12-31', source: 'manual' },
        { date: '2026-08-14', source: 'manual' }
      ]);
    });

    it('keeps future facts in normalized data but excludes them from derived periods', 0, () => {
      const days: Array<MenstrualDay> = [
        { date: '2026-08-14', source: 'manual' },
        { date: '2026-08-20', source: 'manual' }
      ];
      expect(normalizeDays(days).length).assertEqual(2);
      const periods = derivePeriods(days, '2026-08-14');
      expect(periods.length).assertEqual(1);
      expect(periods[0].startDate).assertEqual('2026-08-14');
    });

    it('builds a fixed Monday-start six-week calendar with a zero-based month', 0, () => {
      const cells = buildCalendarCells(2026, 7);
      expect(cells.length).assertEqual(42);
      expect(cells[0].date).assertEqual('2026-07-27');
      expect(cells[0].inCurrentMonth).assertFalse();
      expect(cells[5].date).assertEqual('2026-08-01');
      expect(cells[5].inCurrentMonth).assertTrue();
    });

    it('uses the upper median completed cycle length for prediction', 0, () => {
      const periods: Array<PeriodSummary> = [
        { startDate: '2025-01-01', endDate: '2025-01-27', durationDays: 27, ongoing: false },
        { startDate: '2025-01-29', endDate: '2025-02-25', durationDays: 28, ongoing: false },
        { startDate: '2025-02-26', endDate: '2025-03-30', durationDays: 33, ongoing: false },
        { startDate: '2025-03-31', endDate: '2025-05-02', durationDays: 33, ongoing: false },
        { startDate: '2025-05-03', endDate: '2025-06-04', durationDays: 33, ongoing: false },
        { startDate: '2025-06-10', endDate: '2025-06-10', durationDays: 1, ongoing: true }
      ];
      const prediction = predictNextPeriod(periods);
      expect(prediction.available).assertTrue();
      expect(prediction.label).assertEqual('2025年6月5日左右');
    });

    it('does not predict before three completed periods are available', 0, () => {
      const periods: Array<PeriodSummary> = [
        { startDate: '2025-01-01', endDate: '2025-01-03', durationDays: 3, ongoing: false },
        { startDate: '2025-01-29', endDate: '2025-01-31', durationDays: 3, ongoing: false },
        { startDate: '2025-02-26', endDate: '2025-03-01', durationDays: 4, ongoing: true }
      ];
      expect(predictNextPeriod(periods).available).assertFalse();
    });
  });
}

function durationFor(
  periods: Array<PeriodSummary>,
  startDate: string
): number {
  const period = periods.find((item: PeriodSummary): boolean => {
    return item.startDate === startDate;
  });
  return period === undefined ? 0 : period.durationDays;
}
