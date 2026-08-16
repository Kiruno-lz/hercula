import { describe, it, expect } from '@ohos/hypium';
import { parseJsonDateCandidates } from '../main/ets/data/JsonTransfer';
import { createImportedDays, validateTextImport } from '../main/ets/domain/ImportPipeline';

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
      const result = validateTextImport({
        text: jsonResult.dates.join('\n'),
        jsonIssues: {
          invalidTokens: jsonResult.invalidTokens,
          duplicateDates: jsonResult.duplicateDates
        },
        existingDates: ['2026-08-10'],
        today: '2026-08-14',
        currentYear: 2026
      });

      expect(result.candidateDates).assertDeepEquals(['2026-08-10', '2026-08-14', '2026-08-20']);
      expect(result.validDates).assertDeepEquals(['2026-08-14']);
      expect(result.existingDates).assertDeepEquals(['2026-08-10']);
      expect(result.futureDates).assertDeepEquals(['2026-08-20']);
      expect(result.duplicateDates).assertDeepEquals(['2026-08-10']);
      expect(result.invalidTokens).assertDeepEquals([]);
    });

    it('keeps JSON issues after the user edits the returned text', 0, () => {
      const result = validateTextImport({
        text: '2026-08-14',
        jsonIssues: {
          invalidTokens: ['2026-02-29'],
          duplicateDates: ['2026-08-10']
        },
        existingDates: [],
        today: '2026-08-14',
        currentYear: 2026
      });

      expect(result.validDates).assertDeepEquals(['2026-08-14']);
      expect(result.invalidTokens).assertDeepEquals(['2026-02-29']);
      expect(result.duplicateDates).assertDeepEquals(['2026-08-10']);
    });

    it('creates imported facts only from confirmed valid dates', 0, () => {
      expect(createImportedDays(['2026-08-14', '2026-08-15'])).assertDeepEquals([
        { date: '2026-08-14', source: 'import' },
        { date: '2026-08-15', source: 'import' }
      ]);
    });

    it('does not create import candidates from an empty JSON days array', 0, () => {
      const result = parseJsonDateCandidates(JSON.stringify({
        schemaVersion: 1,
        exportedAt: '2026-08-14T00:00:00.000Z',
        days: []
      }));
      const validation = validateTextImport({
        text: result.dates.join('\n'),
        jsonIssues: {
          invalidTokens: result.invalidTokens,
          duplicateDates: result.duplicateDates
        },
        existingDates: [],
        today: '2026-08-14',
        currentYear: 2026
      });
      expect(validation.candidateDates).assertDeepEquals([]);
      expect(validation.validDates).assertDeepEquals([]);
      expect(validation.invalidTokens).assertDeepEquals([]);
    });
  });
}
