import { describe, it, expect } from '@ohos/hypium';
import {
  classifyLayoutMode,
  resolveRuntimeLayoutMetrics
} from '../main/ets/domain/ResponsiveLayout';

export default function responsiveLayoutTest() {
  describe('ResponsiveLayout', () => {
    it('prioritizes compact for a small square window', 0, () => {
      expect(classifyLayoutMode(980, 980)).assertEqual('compact');
    });

    it('does not classify a large near-square portrait as compact', 0, () => {
      expect(classifyLayoutMode(2210, 2416)).assertEqual('single');
    });

    it('keeps a low-resolution wide window in single mode', 0, () => {
      expect(classifyLayoutMode(980, 653)).assertEqual('single');
    });

    it('uses dual only when the standard ratio has enough room', 0, () => {
      expect(classifyLayoutMode(2584, 1828)).assertEqual('dual');
      expect(classifyLayoutMode(980, 653)).assertEqual('single');
    });

    it('supports the large near-square landscape exception', 0, () => {
      expect(classifyLayoutMode(2416, 2210)).assertEqual('dual');
    });

    it('uses scroll below the expanded threshold', 0, () => {
      expect(classifyLayoutMode(1080, 2444)).assertEqual('scroll');
      expect(classifyLayoutMode(1320, 2200)).assertEqual('single');
    });

    it('keeps extremely wide rotation in scroll mode', 0, () => {
      expect(classifyLayoutMode(2200, 1000)).assertEqual('scroll');
    });

    it('falls back to single for invalid initial dimensions', 0, () => {
      expect(classifyLayoutMode(0, 0)).assertEqual('single');
    });

    it('centralizes the baseline metrics for a single window', 0, () => {
      const metrics = resolveRuntimeLayoutMetrics(1320, 2120, 0, 0, 3);
      expect(metrics.mode).assertEqual('single');
      expect(metrics.calendarGridRowGapVp).assertEqual(15);
      expect(metrics.calendarTitleFontSizeVp).assertEqual(68);
      expect(metrics.calendarYearButtonWidthVp).assertEqual(86);
      expect(metrics.calendarMonthButtonWidthVp).assertEqual(58);
      expect(metrics.actionMenuExpandedWidthVp).assertEqual(184);
      expect(metrics.actionMenuRightInsetRatio).assertEqual(0.08);
      expect(metrics.actionMenuBottomInsetRatio).assertEqual(0.08);
      expect(metrics.historyShortBarThresholdRatio).assertEqual(0.05);
      expect(metrics.historyShortBarOffsetVp).assertEqual(3);
      expect(metrics.fixedActionMenu).assertFalse();
    });

    it('marks the scroll action menu as fixed in the runtime metrics', 0, () => {
      const metrics = resolveRuntimeLayoutMetrics(1320, 2856);
      expect(metrics.mode).assertEqual('scroll');
      expect(metrics.fixedActionMenu).assertTrue();
      expect(metrics.compactHistoryEnabled).assertFalse();
    });

    it('enables the compact history page in compact mode', 0, () => {
      const metrics = resolveRuntimeLayoutMetrics(980, 980);
      expect(metrics.mode).assertEqual('compact');
      expect(metrics.compactHistoryEnabled).assertTrue();
      expect(metrics.compactHistoryContainerRatio).assertEqual(0.95);
    });

    it('derives the single top inset from the Pura X baseline after safe areas', 0, () => {
      const metrics = resolveRuntimeLayoutMetrics(1320, 2120, 80, 40);
      expect(metrics.safeAreaTopInsetVp).assertEqual(80);
      expect(metrics.safeAreaBottomInsetVp).assertEqual(40);
      expect(metrics.calendarTopInsetVp > 381.9).assertEqual(true);
      expect(metrics.calendarTopInsetVp < 382.1).assertEqual(true);
      expect(metrics.calendarBottomInsetVp > 24).assertEqual(true);
    });

    it('keeps a minimum bottom guard on short windows', 0, () => {
      const metrics = resolveRuntimeLayoutMetrics(1320, 1000, 80, 40);
      expect(metrics.calendarBottomInsetVp >= 24).assertEqual(true);
    });

    it('converts pixel safe areas and baseline padding into vp', 0, () => {
      const metrics = resolveRuntimeLayoutMetrics(1320, 2120, 80, 40, 2);
      expect(metrics.safeAreaTopInsetVp).assertEqual(40);
      expect(metrics.safeAreaBottomInsetVp).assertEqual(20);
      expect(metrics.calendarTopInsetVp > 190.9).assertEqual(true);
      expect(metrics.calendarTopInsetVp < 191.1).assertEqual(true);
    });

    it('scales the title down for a narrow scroll calendar', 0, () => {
      const metrics = resolveRuntimeLayoutMetrics(1080, 2444, 0, 0, 3.125);
      expect(metrics.mode).assertEqual('scroll');
      expect(metrics.calendarTitleFontSizeVp < 68).assertEqual(true);
      expect(metrics.calendarTitleFontSizeVp > 48).assertEqual(true);
    });

    it('scales the title from the dual calendar column width', 0, () => {
      const metrics = resolveRuntimeLayoutMetrics(2584, 1828, 0, 0, 3);
      expect(metrics.mode).assertEqual('dual');
      expect(metrics.calendarTitleFontSizeVp < 68).assertEqual(true);
      expect(metrics.calendarTitleFontSizeVp > 48).assertEqual(true);
    });

    it('applies the dual calendar top inset ratio to available space', 0, () => {
      const metrics = resolveRuntimeLayoutMetrics(2584, 1828, 0, 0, 3);
      expect(metrics.mode).assertEqual('dual');
      expect(metrics.calendarTopInsetRatio).assertEqual(0.5);
      expect(metrics.calendarTopInsetVp > 17.1).assertEqual(true);
      expect(metrics.calendarTopInsetVp < 17.2).assertEqual(true);
    });

    it('keeps selector labels usable in compact and scroll modes', 0, () => {
      const compactMetrics = resolveRuntimeLayoutMetrics(980, 980, 0, 0, 3);
      const scrollMetrics = resolveRuntimeLayoutMetrics(1080, 2444, 0, 0, 3.125);
      expect(compactMetrics.calendarYearButtonWidthVp >= 82).assertEqual(true);
      expect(compactMetrics.calendarMonthButtonWidthVp >= 54).assertEqual(true);
      expect(scrollMetrics.calendarYearButtonWidthVp >= 82).assertEqual(true);
      expect(scrollMetrics.calendarMonthButtonWidthVp >= 54).assertEqual(true);
    });

    it('compresses the calendar rows only for a compact canvas below 1000px high', 0, () => {
      const compactMetrics = resolveRuntimeLayoutMetrics(980, 980, 0, 0, 3);
      const singleMetrics = resolveRuntimeLayoutMetrics(1320, 2120, 0, 0, 3);
      const dualMetrics = resolveRuntimeLayoutMetrics(2584, 1828, 0, 0, 3);
      const scrollMetrics = resolveRuntimeLayoutMetrics(1080, 2444, 0, 0, 3.125);
      expect(compactMetrics.calendarGridRowGapVp).assertEqual(3);
      expect(singleMetrics.calendarGridRowGapVp).assertEqual(15);
      expect(dualMetrics.calendarGridRowGapVp).assertEqual(15);
      expect(scrollMetrics.calendarGridRowGapVp).assertEqual(3);
      expect(compactMetrics.calendarGridHeightVp).assertEqual(360);
      expect(singleMetrics.calendarGridHeightVp).assertEqual(360);
      expect(dualMetrics.calendarGridHeightVp).assertEqual(360);
      expect(scrollMetrics.calendarGridHeightVp).assertEqual(212);
      expect(compactMetrics.calendarContentWidthRatio).assertEqual(1);
      expect(singleMetrics.calendarContentWidthRatio).assertEqual(0.85);
      expect(dualMetrics.calendarContentWidthRatio).assertEqual(0.85);
      expect(scrollMetrics.calendarContentWidthRatio).assertEqual(1);
      expect(compactMetrics.calendarGridWidthRatio).assertEqual(1);
      expect(singleMetrics.calendarGridWidthRatio).assertEqual(0.92);
      expect(dualMetrics.calendarGridWidthRatio).assertEqual(0.92);
      expect(scrollMetrics.calendarGridWidthRatio).assertEqual(0.92);
      expect(compactMetrics.scrollCalendarHistoryGapVp).assertEqual(0);
      expect(singleMetrics.scrollCalendarHistoryGapVp).assertEqual(0);
      expect(dualMetrics.scrollCalendarHistoryGapVp).assertEqual(0);
      expect(scrollMetrics.scrollCalendarHistoryGapVp).assertEqual(56);
      expect(compactMetrics.scrollHistoryBottomInsetVp).assertEqual(0);
      expect(singleMetrics.scrollHistoryBottomInsetVp).assertEqual(0);
      expect(dualMetrics.scrollHistoryBottomInsetVp).assertEqual(0);
      expect(scrollMetrics.scrollHistoryBottomInsetVp).assertEqual(64);
      expect(scrollMetrics.calendarBottomInsetVp).assertEqual(0);
      expect(scrollMetrics.historyTopInsetRatio).assertEqual(0);
    });
  });
}
