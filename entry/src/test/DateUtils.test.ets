import { describe, it, expect } from '@ohos/hypium';
import { addDays, dayDistance, formatShortDate, isValidDateKey, toDateKey } from '../main/ets/domain/DateUtils';

export default function dateUtilsTest() {
  describe('DateUtils', () => {
    it('accepts real calendar dates and rejects normalized invalid dates', 0, () => {
      expect(isValidDateKey('2024-02-29')).assertTrue();
      expect(isValidDateKey('2025-02-29')).assertFalse();
      expect(isValidDateKey('2026-13-01')).assertFalse();
      expect(isValidDateKey('2026-8-01')).assertFalse();
    });

    it('adds days across month and year boundaries', 0, () => {
      expect(addDays('2026-01-31', 1)).assertEqual('2026-02-01');
      expect(addDays('2026-12-31', 1)).assertEqual('2027-01-01');
      expect(addDays('2026-01-01', -1)).assertEqual('2025-12-31');
    });

    it('calculates signed day distance across a year boundary', 0, () => {
      expect(dayDistance('2025-12-31', '2026-01-01')).assertEqual(1);
      expect(dayDistance('2026-01-01', '2025-12-31')).assertEqual(-1);
    });

    it('formats local dates using the project date-key convention', 0, () => {
      expect(toDateKey(new Date(2026, 7, 14))).assertEqual('2026-08-14');
      expect(formatShortDate('2026-08-14')).assertEqual('8月14日');
    });
  });
}
