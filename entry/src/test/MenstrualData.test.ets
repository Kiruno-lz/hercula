import { describe, it, expect } from '@ohos/hypium';
import { derivePeriods, MenstrualDay, PeriodSummary } from '../main/ets/domain/MenstrualData';

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
