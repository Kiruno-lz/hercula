import { describe, it, expect } from '@ohos/hypium';
import { classifyLayoutMode } from '../main/ets/domain/ResponsiveLayout';

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
  });
}
