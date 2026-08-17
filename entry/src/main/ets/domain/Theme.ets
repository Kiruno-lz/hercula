export type ThemeId = 'rose' | 'sage' | 'coral' | 'indigo';

export interface ThemePalette {
  id: ThemeId;
  swatch: string;
  pageBackground: string;
  pageBackgroundDeep: string;
  text: string;
  mutedText: string;
  accent: string;
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
  period: '#C98291',
  periodText: '#FFFFFF',
  selectorBackground: '#FFF9F9',
  selectorSelectedBackground: '#E9C9D0',
  glassSurface: '#E9FFF9FA',
  glassBorder: '#B8FFFFFF',
  glassShadow: '#459B7280',
  scrim: '#38F1DDE1',
  primaryButton: '#D78193',
  secondaryButton: '#EAD1D6',
  placeholderBorder: '#D8BFC7',
  divider: '#28FFFFFF',
  backgroundOrbPrimary: '#C9829166',
  backgroundOrbSecondary: '#E9C9D066',
  backgroundOrbTertiary: '#B9CDE566',
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
  backgroundOrbPrimary: '#87AA9666',
  backgroundOrbSecondary: '#C4DDCC66',
  backgroundOrbTertiary: '#B9CDE566',
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
  backgroundOrbPrimary: '#D4877266',
  backgroundOrbSecondary: '#EBC3B366',
  backgroundOrbTertiary: '#D8C6B966',
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
  backgroundOrbPrimary: '#7F8FC166',
  backgroundOrbSecondary: '#B8C5E566',
  backgroundOrbTertiary: '#C6CBE066',
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
