import { describe, it, expect } from '@ohos/hypium';
import { classifyJsonFileSize, parseJsonDateCandidates } from '../main/ets/data/JsonTransfer';

interface TestJsonDay {
  date: string;
  source: string;
}

interface TestJsonPayload {
  schemaVersion: number;
  exportedAt: string;
  days: Array<TestJsonDay>;
}

export default function jsonTransferTest() {
  describe('JsonTransfer', () => {
    it('classifies file size boundaries before reading', 0, () => {
      expect(classifyJsonFileSize(0)).assertEqual('empty');
      expect(classifyJsonFileSize(4 * 1024 * 1024)).assertEqual('success');
      expect(classifyJsonFileSize(4 * 1024 * 1024 + 1)).assertEqual('too-large');
    });

    it('parses schema v1 dates and reports duplicates', 0, () => {
      const payload: TestJsonPayload = {
        schemaVersion: 1,
        exportedAt: '2026-08-14T00:00:00.000Z',
        days: [
          { date: '2026-05-09', source: 'manual' },
          { date: '2026-05-09', source: 'import' },
          { date: '2026-06-16', source: 'import' }
        ]
      };
      const result = parseJsonDateCandidates(JSON.stringify(payload));
      expect(result.dates).assertDeepEquals(['2026-05-09', '2026-06-16']);
      expect(result.duplicateDates).assertDeepEquals(['2026-05-09']);
      expect(result.invalidTokens).assertDeepEquals([]);
    });

    it('keeps invalid item dates for confirmation', 0, () => {
      const payload: TestJsonPayload = {
        schemaVersion: 1,
        exportedAt: '2026-08-14T00:00:00.000Z',
        days: [
          { date: '2026-02-29', source: 'import' },
          { date: '2026-08-14', source: 'import' },
          { date: '2026-13-01', source: 'invalid' }
        ]
      };
      const result = parseJsonDateCandidates(JSON.stringify(payload));
      expect(result.dates).assertDeepEquals(['2026-08-14']);
      expect(result.invalidTokens).assertDeepEquals(['2026-02-29', '2026-13-01']);
    });

    it('rejects an unsupported schema', 0, () => {
      let rejected: boolean = false;
      try {
        parseJsonDateCandidates('{"schemaVersion":2,"exportedAt":"2026-08-14T00:00:00.000Z","days":[]}');
      } catch (_error) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });
  });
}
