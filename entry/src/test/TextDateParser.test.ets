import { describe, it, expect } from '@ohos/hypium';
import { TextDateParseResult, parseTextDates } from '../main/ets/domain/TextDateParser';

function assertParseResult(input: string, dates: Array<string>, invalidTokens: Array<string>): void {
  const result: TextDateParseResult = parseTextDates(input);
  expect(result.dates).assertDeepEquals(dates);
  expect(result.invalidTokens).assertDeepEquals(invalidTokens);
}

export default function textDateParserTest() {
  describe('TextDateParser', () => {
    it('parses hyphen slash and dot dates', 0, () => {
      assertParseResult(
        '2026-08-14, 2026/8/15; 2026.08.16',
        ['2026-08-14', '2026-08-15', '2026-08-16'],
        []
      );
    });

    it('parses Chinese date notation', 0, () => {
      assertParseResult('初次 2026年8月1日，之后 2026年08月02日',
        ['2026-08-01', '2026-08-02'], []);
    });

    it('parses dates from simple surrounding text', 0, () => {
      assertParseResult('经期开始：2026-08-03\n下一次：2026/09/01',
        ['2026-08-03', '2026-09-01'], []);
    });

    it('deduplicates repeated dates', 0, () => {
      assertParseResult('2026-08-14 2026/08/14 2026年8月14日',
        ['2026-08-14'], []);
    });

    it('rejects impossible calendar dates', 0, () => {
      assertParseResult('2026-02-29, 2026-04-31, 2026年13月01日', [],
        ['2026-02-29', '2026-04-31', '2026年13月01日']);
    });

    it('rejects mixed separators', 0, () => {
      assertParseResult('2026-08/14', [], ['2026-08/14']);
    });

    it('rejects unsupported year and compact formats', 0, () => {
      assertParseResult('26-08-14, 20260814', [], ['26-08-14', '20260814']);
    });

    it('rejects Chinese notation without the day suffix', 0, () => {
      assertParseResult('2026年8月14', [], ['2026年8月14']);
    });

    it('returns no dates for empty or non-date text', 0, () => {
      assertParseResult('   只是备注，没有日期   ', [], []);
      assertParseResult('', [], []);
    });
  });
}
