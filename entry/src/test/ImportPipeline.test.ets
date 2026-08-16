import { describe, it, expect } from '@ohos/hypium';
import { parseJsonDateCandidates } from '../main/ets/data/JsonTransfer';
import { validateImportDates } from '../main/ets/domain/ImportValidator';
import { parseTextDates } from '../main/ets/domain/TextDateParser';

interface TestJsonDay {
  date: string;
  source: string;
}

interface TestJsonPayload {
  schemaVersion: number;
  exportedAt: string;
  days: Array<TestJsonDay>;
}

export default function importPipelineTest() {
  describe('ImportPipeline', () => {
    it('preserves JSON issues while replaying candidates through text validation', 0, () => {
      const payload: TestJsonPayload = {
        schemaVersion: 1,
        exportedAt: '2026-08-14T00:00:00.000Z',
        days: [
          { date: '2026-08-10', source: 'manual' },
          { date: '2026-08-10', source: 'import' },
          { date: '2026-08-14', source: 'import' },
          { date: '2026-08-20', source: 'import' }
        ]
      };
      const jsonResult = parseJsonDateCandidates(JSON.stringify(payload));
      const textResult = parseTextDates(jsonResult.dates.join('\n'), 2026);
      const result = validateImportDates({
        dates: textResult.dates,
        invalidTokens: jsonResult.invalidTokens.concat(textResult.invalidTokens),
        duplicateDates: jsonResult.duplicateDates.concat(textResult.duplicateDates),
        existingDates: ['2026-08-10'],
        today: '2026-08-14'
      });

      expect(result.candidateDates).assertDeepEquals(['2026-08-10', '2026-08-14', '2026-08-20']);
      expect(result.validDates).assertDeepEquals(['2026-08-14']);
      expect(result.existingDates).assertDeepEquals(['2026-08-10']);
      expect(result.futureDates).assertDeepEquals(['2026-08-20']);
      expect(result.duplicateDates).assertDeepEquals(['2026-08-10']);
      expect(result.invalidTokens).assertDeepEquals([]);
    });

    it('does not create import candidates from an empty JSON days array', 0, () => {
      const result = parseJsonDateCandidates(JSON.stringify({
        schemaVersion: 1,
        exportedAt: '2026-08-14T00:00:00.000Z',
        days: []
      }));
      const validation = validateImportDates({
        dates: result.dates,
        invalidTokens: result.invalidTokens,
        duplicateDates: result.duplicateDates,
        existingDates: [],
        today: '2026-08-14'
      });
      expect(validation.candidateDates).assertDeepEquals([]);
      expect(validation.validDates).assertDeepEquals([]);
      expect(validation.invalidTokens).assertDeepEquals([]);
    });
  });
}
