import { describe, it, expect } from '@ohos/hypium';
import {
  derivePeriods,
  CycleForecast,
  MenstrualDay,
  normalizeDays,
  PeriodSummary,
  predictCycleForecast,
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

    it('uses a time-weighted average and the latest start as the prediction anchor', 0, () => {
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
      expect(prediction.label).assertEqual('2025年7月10-19日左右');
    });

    it('derives calendar ovulation from a 14-day luteal phase window', 0, () => {
      const periods: Array<PeriodSummary> = [
        { startDate: '2025-01-01', endDate: '2025-01-27', durationDays: 27, ongoing: false },
        { startDate: '2025-01-29', endDate: '2025-02-25', durationDays: 28, ongoing: false },
        { startDate: '2025-02-26', endDate: '2025-03-30', durationDays: 33, ongoing: false },
        { startDate: '2025-03-31', endDate: '2025-05-02', durationDays: 33, ongoing: false },
        { startDate: '2025-05-03', endDate: '2025-06-04', durationDays: 33, ongoing: false },
        { startDate: '2025-06-10', endDate: '2025-06-10', durationDays: 1, ongoing: true }
      ];
      const forecast = predictCycleForecast(periods);

      expect(forecast === undefined).assertFalse();
      expect((forecast as CycleForecast).nextPeriodStartDate).assertEqual('2025-07-14');
      expect((forecast as CycleForecast).estimatedCycleLengthDays).assertEqual(34);
      expect((forecast as CycleForecast).probabilityBandwidthDays >= 1.5).assertTrue();
      expect((forecast as CycleForecast).probabilityBandwidthDays <= 4.5).assertTrue();
      expect((forecast as CycleForecast).ovulation.method).assertEqual('calendar');
      expect((forecast as CycleForecast).ovulation.date).assertEqual('2025-06-30');
      expect((forecast as CycleForecast).ovulation.windowStart).assertEqual('2025-06-27');
      expect((forecast as CycleForecast).ovulation.windowEnd).assertEqual('2025-07-03');
      expect((forecast as CycleForecast).periodProbability.length > 0).assertTrue();
      expect((forecast as CycleForecast).highProbabilityDates[0]).assertEqual('2025-07-10');
      expect((forecast as CycleForecast).highProbabilityDates[
        (forecast as CycleForecast).highProbabilityDates.length - 1
      ]).assertEqual('2025-07-19');
      let probabilityTotal: number = 0;
      (forecast as CycleForecast).periodProbability.forEach((item): void => {
        probabilityTotal += item.probability;
      });
      expect(probabilityTotal > 0.99).assertTrue();
      expect(probabilityTotal < 1.01).assertTrue();
    });

    it('does not predict before three period start dates are available', 0, () => {
      const periods: Array<PeriodSummary> = [
        { startDate: '2025-01-01', endDate: '2025-01-03', durationDays: 3, ongoing: false },
        { startDate: '2025-01-29', endDate: '2025-01-31', durationDays: 3, ongoing: true }
      ];
      expect(predictNextPeriod(periods).available).assertFalse();

      const threeStarts: Array<PeriodSummary> = periods.concat([
        { startDate: '2025-02-26', endDate: '2025-03-01', durationDays: 4, ongoing: true }
      ]);
      expect(predictNextPeriod(threeStarts).available).assertTrue();
    });

    it('keeps the calendar forecast available with one or two starts', 0, () => {
      const oneStart: Array<PeriodSummary> = [
        { startDate: '2025-01-01', endDate: '2025-01-01', durationDays: 1, ongoing: true }
      ];
      const twoStarts: Array<PeriodSummary> = [
        { startDate: '2025-01-01', endDate: '2025-01-27', durationDays: 27, ongoing: false },
        { startDate: '2025-01-29', endDate: '2025-01-29', durationDays: 1, ongoing: true }
      ];
      const oneStartForecast = predictCycleForecast(oneStart);
      const twoStartForecast = predictCycleForecast(twoStarts);

      expect((oneStartForecast as CycleForecast).estimatedCycleLengthDays).assertEqual(28);
      expect((oneStartForecast as CycleForecast).periodProbability.length > 0).assertTrue();
      expect((twoStartForecast as CycleForecast).estimatedCycleLengthDays).assertEqual(28);
      expect((twoStartForecast as CycleForecast).periodProbability.length > 0).assertTrue();
      expect(predictNextPeriod(oneStart).available).assertFalse();
      expect(predictNextPeriod(twoStarts).available).assertFalse();
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
