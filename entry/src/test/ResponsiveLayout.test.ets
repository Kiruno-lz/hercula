import { describe, it, expect } from '@ohos/hypium';
import {
  classifyLayoutMode,
  resolveRuntimeLayoutMetrics
} from '../main/ets/domain/ResponsiveLayout';

export default function responsiveLayoutTest() {
  describe('ResponsiveLayout', () => {
    it('prioritizes compact for a small near-square window', 0, () => {
      expect(classifyLayoutMode(980, 980)).assertEqual('compact');
      expect(classifyLayoutMode(1000, 1000)).assertEqual('compact');
    });

    it('does not use compact for a large near-square window', 0, () => {
      expect(classifyLayoutMode(1320, 1320)).assertEqual('single');
    });

    it('classifies the standard dual ratio and low-resolution dual ratio as dual', 0, () => {
      expect(classifyLayoutMode(2584, 1828)).assertEqual('dual');
      expect(classifyLayoutMode(980, 653)).assertEqual('dual');
    });

    it('classifies large near-square Mate X7 orientations as dual', 0, () => {
      expect(classifyLayoutMode(2210, 2416)).assertEqual('dual');
      expect(classifyLayoutMode(2416, 2210)).assertEqual('dual');
    });

    it('keeps the Pura X folded aspect ratio in single mode', 0, () => {
      expect(classifyLayoutMode(1264, 1848)).assertEqual('single');
      expect(classifyLayoutMode(1320, 2120)).assertEqual('single');
    });

    it('uses scroll outside the supported portrait and landscape ratios', 0, () => {
      expect(classifyLayoutMode(1080, 2444)).assertEqual('scroll');
      expect(classifyLayoutMode(1320, 2856)).assertEqual('scroll');
      expect(classifyLayoutMode(2200, 1000)).assertEqual('scroll');
    });

    it('keeps exact scroll and dual boundaries deterministic', 0, () => {
      expect(classifyLayoutMode(1320, 2200)).assertEqual('single');
      expect(classifyLayoutMode(1800, 1000)).assertEqual('dual');
    });

    it('falls back to single for invalid initial dimensions', 0, () => {
      expect(classifyLayoutMode(0, 0)).assertEqual('single');
      expect(classifyLayoutMode(-1, 100)).assertEqual('single');
    });

    it('exposes semantic runtime flags without changing the full window dimensions', 0, () => {
      const compactMetrics = resolveRuntimeLayoutMetrics(980, 980);
      const singleMetrics = resolveRuntimeLayoutMetrics(1264, 1848);
      const dualMetrics = resolveRuntimeLayoutMetrics(2584, 1828);
      const scrollMetrics = resolveRuntimeLayoutMetrics(1320, 2856, 80, 40);

      expect(compactMetrics.compactHistoryEnabled).assertTrue();
      expect(compactMetrics.fixedActionMenu).assertFalse();
      expect(singleMetrics.compactHistoryEnabled).assertFalse();
      expect(singleMetrics.fixedActionMenu).assertFalse();
      expect(dualMetrics.fixedActionMenu).assertFalse();
      expect(scrollMetrics.compactHistoryEnabled).assertFalse();
      expect(scrollMetrics.fixedActionMenu).assertTrue();
      expect(scrollMetrics.viewportWidth).assertEqual(1320);
      expect(scrollMetrics.viewportHeight).assertEqual(2856);
    });
  });
}
