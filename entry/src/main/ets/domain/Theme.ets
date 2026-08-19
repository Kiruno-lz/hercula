export type ThemeId = 'rose' | 'sage' | 'coral' | 'indigo';

export interface ThemePalette {
  id: ThemeId;
  swatch: string;
  pageBackground: string;
  pageBackgroundDeep: string;
  text: string;
  mutedText: string;
  accent: string;
  contrastColor: string;
  period: string;
  periodText: string;
  selectorBackground: string;
  selectorSelectedBackground: string;
  glassSurface: string;
  glassBorder: string;
  glassShadow: string;
  scrim: string;
  primaryButton: string;
  secondaryButton: string;
  placeholderBorder: string;
  divider: string;
  backgroundOrbPrimary: string;
  backgroundOrbSecondary: string;
  backgroundOrbTertiary: string;
  backgroundBlurOverlay: string;
  welcomeBullet: string;
  loadingPrimary: string;
  loadingSecondary: string;
  loadingContrast: string;
}

export const DEFAULT_THEME_ID: ThemeId = 'rose';

const ROSE_THEME: ThemePalette = {
  id: 'rose',
  swatch: '#C98291',
  pageBackground: '#F8F2F3',
  pageBackgroundDeep: '#F1DDE1',
  text: '#594B50',
  mutedText: '#8E7B82',
  accent: '#A95E70',
  contrastColor: '#ffC98291',
  period: '#C98291',
  periodText: '#FFFFFF',
  selectorBackground: '#FFF9F9',
  selectorSelectedBackground: '#E9C9D0',
  glassSurface: '#E9FFF9FA',
  glassBorder: '#B8FFFFFF',
  glassShadow: '#459B7280',
  scrim: '#38F1DDE1',
  primaryButton: '#D78193',
  secondaryButton: '#f3c9d2',
  placeholderBorder: '#D8BFC7',
  divider: '#28FFFFFF',
  backgroundOrbPrimary: '#70D77B91',
  backgroundOrbSecondary: '#57e29af0',
  backgroundOrbTertiary: '#40F3E5E8',
  backgroundBlurOverlay: '#24FFFFFF',
  welcomeBullet: '#40F3E5E8',
  loadingPrimary: '#C98291',
  loadingSecondary: '#E7C6CD',
  loadingContrast: '#D5DEE7'
};

const SAGE_THEME: ThemePalette = {
  id: 'sage',
  swatch: '#87AA96',
  pageBackground: '#F2F6F1',
  pageBackgroundDeep: '#DCE9DF',
  text: '#46534A',
  mutedText: '#84938A',
  accent: '#668875',
  contrastColor: '#7E6f927c',
  period: '#87AA96',
  periodText: '#FFFFFF',
  selectorBackground: '#FAFDF9',
  selectorSelectedBackground: '#D6E7DC',
  glassSurface: '#E9F9FCF8',
  glassBorder: '#B8FFFFFF',
  glassShadow: '#4580A58C',
  scrim: '#385B7A63',
  primaryButton: '#7FA891',
  secondaryButton: '#D9E9DE',
  placeholderBorder: '#BFD3C5',
  divider: '#285F8068',
  backgroundOrbPrimary: '#606F927C',
  backgroundOrbSecondary: '#45D89368',
  backgroundOrbTertiary: '#30243E36',
  backgroundBlurOverlay: '#24FFFFFF',
  welcomeBullet: '#30243E36',
  loadingPrimary: '#87AA96',
  loadingSecondary: '#C7DDCE',
  loadingContrast: '#D5DEE7'
};

const CORAL_THEME: ThemePalette = {
  id: 'coral',
  swatch: '#D48772',
  pageBackground: '#F8F1ED',
  pageBackgroundDeep: '#F0D9CC',
  text: '#5A4640',
  mutedText: '#96786D',
  accent: '#B96F5E',
  contrastColor: '#ffd48672',
  period: '#D48772',
  periodText: '#FFFFFF',
  selectorBackground: '#FFF9F6',
  selectorSelectedBackground: '#F0D1C5',
  glassSurface: '#E9FFF9F6',
  glassBorder: '#B8FFFFFF',
  glassShadow: '#459D705E',
  scrim: '#38F0D9CC',
  primaryButton: '#D98772',
  secondaryButton: '#EFD5CB',
  placeholderBorder: '#D9BEB3',
  divider: '#287D5D52',
  backgroundOrbPrimary: '#5069969b',
  backgroundOrbSecondary: '#60C96F52',
  backgroundOrbTertiary: '#35F4E6D1',
  backgroundBlurOverlay: '#24FFFFFF',
  welcomeBullet: '#35F4E6D1',
  loadingPrimary: '#D48772',
  loadingSecondary: '#E7C9BD',
  loadingContrast: '#D9DDE5'
};

const INDIGO_THEME: ThemePalette = {
  id: 'indigo',
  swatch: '#7F8FC1',
  pageBackground: '#F1F2F8',
  pageBackgroundDeep: '#DCE1F0',
  text: '#464B5A',
  mutedText: '#7F8498',
  accent: '#6476A9',
  contrastColor: '#7EB69AE8',
  period: '#7F8FC1',
  periodText: '#FFFFFF',
  selectorBackground: '#FAFBFF',
  selectorSelectedBackground: '#D6DDF0',
  glassSurface: '#E9FAFBFF',
  glassBorder: '#B8FFFFFF',
  glassShadow: '#456C78A8',
  scrim: '#383E4F80',
  primaryButton: '#7A8ABD',
  secondaryButton: '#DCE1F0',
  placeholderBorder: '#BFC7DF',
  divider: '#286875A0',
  backgroundOrbPrimary: '#502D5B9E',
  backgroundOrbSecondary: '#45B69AE8',
  backgroundOrbTertiary: '#3014243A',
  backgroundBlurOverlay: '#24FFFFFF',
  welcomeBullet: '#3014243A',
  loadingPrimary: '#7F8FC1',
  loadingSecondary: '#CCD3EB',
  loadingContrast: '#D5DEE7'
};

export function resolveTheme(themeId: ThemeId): ThemePalette {
  switch (themeId) {
    case 'sage':
      return SAGE_THEME;
    case 'coral':
      return CORAL_THEME;
    case 'indigo':
      return INDIGO_THEME;
    case 'rose':
    default:
      return ROSE_THEME;
  }
}

export function normalizeThemeId(value: string): ThemeId {
  if (value === 'sage' || value === 'coral' || value === 'indigo') {
    return value;
  }
  return DEFAULT_THEME_ID;
}

export function themeIds(): Array<ThemeId> {
  return ['rose', 'sage', 'coral', 'indigo'];
}
