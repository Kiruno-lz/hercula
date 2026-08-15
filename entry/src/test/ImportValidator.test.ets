import { describe, it, expect } from '@ohos/hypium';
import { validateImportDates } from '../main/ets/domain/ImportValidator';

export default function importValidatorTest() {
  describe('ImportValidator', () => {
    it('keeps only new dates before or on today', 0, () => {
      const result = validateImportDates({
        dates: ['2026-08-10', '2026-08-14', '2026-08-20'],
        invalidTokens: [],
        duplicateDates: [],
        existingDates: ['2026-08-10'],
        today: '2026-08-14'
      });
      expect(result.validDates).assertDeepEquals(['2026-08-14']);
      expect(result.existingDates).assertDeepEquals(['2026-08-10']);
      expect(result.futureDates).assertDeepEquals(['2026-08-20']);
    });

    it('preserves parser issues for confirmation', 0, () => {
      const result = validateImportDates({
        dates: ['2026-08-14'],
        invalidTokens: ['2026-02-29'],
        duplicateDates: ['2026-08-14'],
        existingDates: [],
        today: '2026-08-14'
      });
      expect(result.validDates).assertDeepEquals(['2026-08-14']);
      expect(result.invalidTokens).assertDeepEquals(['2026-02-29']);
      expect(result.duplicateDates).assertDeepEquals(['2026-08-14']);
    });
  });
}
