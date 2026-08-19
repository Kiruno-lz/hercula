import { describe, it, expect } from '@ohos/hypium';
import {
  DEFAULT_THEME_ID,
  normalizeThemeId,
  resolveTheme,
  themeIds,
  ThemeId
} from '../main/ets/domain/Theme';

export default function themeTest() {
  describe('Theme', () => {
    it('provides exactly the four supported theme ids', 0, () => {
      expect(themeIds()).assertDeepEquals(['rose', 'sage', 'coral', 'indigo']);
    });

    it('normalizes unknown persisted values to the default theme', 0, () => {
      expect(normalizeThemeId('unknown')).assertEqual(DEFAULT_THEME_ID);
      expect(normalizeThemeId('sage')).assertEqual('sage');
    });

    it('keeps each theme internally coherent', 0, () => {
      themeIds().forEach((themeId: ThemeId): void => {
        const theme = resolveTheme(themeId);
        expect(theme.id).assertEqual(themeId);
        expect(theme.swatch.length > 0).assertTrue();
        expect(theme.pageBackground.length > 0).assertTrue();
        expect(theme.period.length > 0).assertTrue();
        expect(theme.glassSurface.length > 0).assertTrue();
        expect(theme.welcomeBullet.length > 0).assertTrue();
        expect(theme.loadingPrimary.length > 0).assertTrue();
      });
    });
  });
}
