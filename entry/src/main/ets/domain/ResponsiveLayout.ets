export type PageLayoutMode = 'compact' | 'single' | 'dual' | 'scroll';

export interface RuntimeLayoutMetrics {
  mode: PageLayoutMode;
  viewportWidth: number;
  viewportHeight: number;
  safeAreaTopInsetVp: number;
  safeAreaBottomInsetVp: number;
  contentHeightVp: number;
  calendarTopInsetVp: number;
  calendarBottomInsetVp: number;
  calendarTopInsetRatio: number;
  calendarBottomInsetRatio: number;
  calendarInnerTopInsetRatio: number;
  calendarMonthCardTopInsetRatio: number;
  calendarMonthCardTopInsetVp: number;
  calendarHorizontalPaddingVp: number;
  calendarContentWidthRatio: number;
  calendarGridWidthRatio: number;
  calendarHeight: string;
  calendarYearLabelShortThresholdVp: number;
  calendarTitleFontSizeVp: number;
  calendarSubtitleFontSizeVp: number;
  calendarSelectorVerticalGapVp: number;
  calendarSelectorHorizontalGapVp: number;
  calendarSelectorHeightVp: number;
  calendarYearButtonWidthVp: number;
  calendarMonthButtonWidthVp: number;
  calendarJumpPanelHeightVp: number;
  calendarGridHeightVp: number;
  calendarGridContainerHeightVp: number;
  calendarGridRowGapVp: number;
  calendarGridColumnGapVp: number;
  calendarDateSizeVp: number;
  calendarDateRowHeightVp: number;
  historyTopInsetRatio: number;
  historyBottomInsetRatio: number;
  historySectionGapVp: number;
  scrollCalendarHistoryGapVp: number;
  scrollHistoryBottomInsetVp: number;
  historyShortBarThresholdRatio: number;
  historyShortBarOffsetVp: number;
  historyPredictionGapVp: number;
  historyPeriodsGapVp: number;
  compactHistoryContainerRatio: number;
  actionMenuCollapsedSizeVp: number;
  actionMenuIconSizeVp: number;
  actionMenuExpandedWidthVp: number;
  actionMenuExpandedHeightVp: number;
  actionMenuItemHeightVp: number;
  actionMenuThemeRowHeightVp: number;
  actionMenuThemeSwatchSizeVp: number;
  actionMenuHorizontalPaddingVp: number;
  actionMenuVerticalPaddingVp: number;
  actionMenuCollapsedAnchorOffsetVp: number;
  actionMenuExpandedAnchorOffsetYVp: number;
  actionMenuRightInsetRatio: number;
  actionMenuBottomInsetRatio: number;
  compactHistoryEnabled: boolean;
  fixedActionMenu: boolean;
}

// 运行时模式只读取完整窗口像素尺寸，不读取扣除安全区后的内容尺寸。
// 调整模式边界时只改这里，避免把设备安全区误当成设备分辨率。
const COMPACT_MAX_DIMENSION: number = 1000;
const COMPACT_MIN_RATIO: number = 0.82;
const COMPACT_MAX_RATIO: number = 1.22;
const SCROLL_MAX_RATIO: number = 0.6;
const DUAL_MIN_RATIO: number = 1.3;
const DUAL_MAX_RATIO: number = 1.8;

// Pura X single（1320×2120）是顶部视觉留白基线。
// - 减小：日历整体上移；增大：日历整体下移。
// 该值作用于 full window height，后续会扣除安全区并从 px 转换为 vp。
const PURA_X_SINGLE_BASELINE_WIDTH: number = 1320;
const PURA_X_SINGLE_BASELINE_HEIGHT: number = 2120;
const PURA_X_SINGLE_TOP_INSET_RATIO: number = 0.18;

// CalendarComponent 内部主内容列宽约占组件宽度的 85%。
// dual 时 CalendarComponent 位于左右两列之一，因此还要乘以 50%。
// 标题字号使用 Pura X single 的 68vp 作为上限基线，按实际内容列宽缩放。
const CALENDAR_CONTENT_WIDTH_RATIO: number = 0.85;
const CALENDAR_GRID_WIDTH_RATIO: number = 0.92;
const CALENDAR_PAGE_HORIZONTAL_PADDING_VP: number = 20;
const DUAL_CALENDAR_TOP_INSET_RATIO: number = 0.2;
// scroll 修改下面四个数值微调对应视觉参数
const SCROLL_CALENDAR_TOP_INSET_RATIO: number = 0.15;
const SCROLL_CALENDAR_HORIZONTAL_PADDING_VP: number = 17;
const SCROLL_CALENDAR_INNER_TOP_INSET_RATIO: number = 0.12;
const SCROLL_CALENDAR_GRID_ROW_GAP_VP: number = 3;
const CALENDAR_DATE_ROW_COUNT: number = 5;
const CALENDAR_DATE_ROW_HEIGHT_VP: number = 40;
const SINGLE_CALENDAR_GRID_ROW_GAP_BASELINE_VP: number = 15;
const SCROLL_HISTORY_BOTTOM_INSET_VP: number = 64;
const HISTORY_SHORT_BAR_THRESHOLD_RATIO: number = 0.05;
const HISTORY_SHORT_BAR_OFFSET_VP: number = 3;
const COMPACT_HISTORY_CONTAINER_RATIO: number = 0.95;
const DUAL_CALENDAR_COLUMN_WIDTH_RATIO: number = 0.5;
const PURA_X_SINGLE_BASELINE_DENSITY_PIXELS: number = 3;
const PURA_X_SINGLE_CALENDAR_CONTENT_WIDTH_VP: number =
  (PURA_X_SINGLE_BASELINE_WIDTH / PURA_X_SINGLE_BASELINE_DENSITY_PIXELS)
    * CALENDAR_CONTENT_WIDTH_RATIO;
const PURA_X_SINGLE_BASELINE_PAGE_WIDTH_VP: number =
  PURA_X_SINGLE_BASELINE_WIDTH / PURA_X_SINGLE_BASELINE_DENSITY_PIXELS;
const PURA_X_SINGLE_BASELINE_PAGE_HEIGHT_VP: number =
  PURA_X_SINGLE_BASELINE_HEIGHT / PURA_X_SINGLE_BASELINE_DENSITY_PIXELS;
const CALENDAR_TITLE_BASELINE_FONT_SIZE_VP: number = 68;
const CALENDAR_TITLE_MIN_FONT_SIZE_VP: number = 48;
const CALENDAR_TITLE_MAX_FONT_SIZE_VP: number = 68;
const CALENDAR_SUBTITLE_FONT_SIZE_VP: number = 24;
const CALENDAR_SELECTOR_HEIGHT_VP: number = 38;
const CALENDAR_DATE_SIZE_VP: number = 38;
const CALENDAR_GRID_COLUMN_GAP_VP: number = 2;
const CALENDAR_MONTH_CARD_TOP_INSET_RATIO: number = 0.0167;
const CALENDAR_YEAR_LABEL_SHORT_THRESHOLD_VP: number = 1200;
const SINGLE_CALENDAR_GRID_ROW_GAP_RATIO: number =
  SINGLE_CALENDAR_GRID_ROW_GAP_BASELINE_VP / PURA_X_SINGLE_BASELINE_PAGE_HEIGHT_VP;
const DUAL_CALENDAR_GRID_ROW_GAP_RATIO: number =
  SINGLE_CALENDAR_GRID_ROW_GAP_BASELINE_VP / PURA_X_SINGLE_BASELINE_PAGE_HEIGHT_VP;
const PURA_X_SINGLE_MONTH_CARD_TOP_INSET_VP: number =
  PURA_X_SINGLE_CALENDAR_CONTENT_WIDTH_VP * CALENDAR_MONTH_CARD_TOP_INSET_RATIO;
const SINGLE_CALENDAR_MONTH_CARD_TOP_INSET_RATIO: number =
  PURA_X_SINGLE_MONTH_CARD_TOP_INSET_VP / PURA_X_SINGLE_BASELINE_PAGE_WIDTH_VP + 0.03;
const ACTION_MENU_RIGHT_INSET_RATIO: number = 0.08;
const ACTION_MENU_BOTTOM_INSET_RATIO: number = 0.08;
// 年份按钮的文本必须保留单行完整显示；月份按钮保留独立的较小下限。
// 宽屏按基线比例增长，窄屏不低于最小可用宽度，避免 Button 内部压缩文字。
const CALENDAR_YEAR_BUTTON_BASELINE_WIDTH_VP: number = 86;
const CALENDAR_MONTH_BUTTON_BASELINE_WIDTH_VP: number = 58;
const CALENDAR_YEAR_BUTTON_MIN_WIDTH_VP: number = 82;
const CALENDAR_MONTH_BUTTON_MIN_WIDTH_VP: number = 54;
const CALENDAR_YEAR_BUTTON_MAX_WIDTH_VP: number = 96;
const CALENDAR_MONTH_BUTTON_MAX_WIDTH_VP: number = 66;
const MIN_BOTTOM_INSET_RATIO: number = 0.02;
const CALENDAR_TITLE_COLUMN_SPACE_VP: number = 2;
const HISTORY_SECTION_GAP_VP: number = 16;
const HISTORY_TOP_INSET_RATIO: number = 0.0212;
const HISTORY_BOTTOM_INSET_RATIO: number = 0.0152;
const ACTION_MENU_COLLAPSED_SIZE_VP: number = 44;
const ACTION_MENU_ICON_SIZE_VP: number = 24;
const ACTION_MENU_EXPANDED_WIDTH_VP: number = 184;
const ACTION_MENU_EXPANDED_HEIGHT_VP: number = 220;
const ACTION_MENU_ITEM_HEIGHT_VP: number = 40;
const ACTION_MENU_THEME_ROW_HEIGHT_VP: number = 32;
const ACTION_MENU_THEME_SWATCH_SIZE_VP: number = 22;
const ACTION_MENU_HORIZONTAL_PADDING_VP: number = 18;
const ACTION_MENU_VERTICAL_PADDING_VP: number = 16;
const ACTION_MENU_COLLAPSED_ANCHOR_OFFSET_VP: number = 140;
const ACTION_MENU_EXPANDED_ANCHOR_OFFSET_Y_VP: number = -176;

interface ModeLayoutConfig {
  calendarContentWidthRatio: number;
  calendarGridWidthRatio: number;
  calendarHorizontalPaddingVp: number;
  calendarInnerTopInsetRatio: number;
  calendarSelectorVerticalGapVp: number;
  calendarGridRowGapVp: number;
  calendarMonthCardTopInsetRatio: number;
  calendarTopInsetRatio: number;
  calendarHeight: string;
  calendarBottomInsetRatio: number;
  historyTopInsetRatio: number;
  historyBottomInsetRatio: number;
  scrollCalendarHistoryGapVp: number;
  scrollHistoryBottomInsetVp: number;
  compactHistoryEnabled: boolean;
  fixedActionMenu: boolean;
}

/**
 * Classify the page from the complete window rectangle.
 * The caller must provide windowRect.width and windowRect.height, not the
 * drawable content area after system safe-area insets.
 *
 * 页面模式与 ResponsivePageShell 的对应关系：
 * - compact：小尺寸近方形，只渲染核心日历，不渲染标题和历史页。
 * - single：上下 Swiper，日历页和历史页分别占满窗口。
 * - dual：左右两列，日历和历史各占一列；日历标题字号按左列宽度缩放。
 * - scroll：日历和历史处于同一个纵向 Scroll，操作菜单固定在窗口右下角。
 */
export function classifyLayoutMode(width: number, height: number): PageLayoutMode {
  if (width <= 0 || height <= 0) {
    return 'single';
  }

  const ratio: number = width / height;
  if (isCompactWindow(width, height, ratio)) {
    return 'compact';
  }
  if (ratio < SCROLL_MAX_RATIO || ratio > DUAL_MAX_RATIO) {
    return 'scroll';
  }
  if (isDualWindow(width, height, ratio)) {
    return 'dual';
  }
  return 'single';
}

export function resolveRuntimeLayoutMetrics(
  width: number,
  height: number,
  safeAreaTopInset: number = 0,
  safeAreaBottomInset: number = 0,
  densityPixels: number = 1
): RuntimeLayoutMetrics {
  const safeWidth: number = Math.max(1, width);
  const safeHeight: number = Math.max(1, height);
  const safeTop: number = Math.max(0, safeAreaTopInset);
  const safeBottom: number = Math.max(0, safeAreaBottomInset);
  const density: number = Math.max(1, densityPixels);
  const contentHeight: number = Math.max(1, (safeHeight - safeTop - safeBottom) / density);
  const mode: PageLayoutMode = classifyLayoutMode(safeWidth, safeHeight);
  const viewportWidthVp: number = safeWidth / density;
  const viewportHeightVp: number = safeHeight / density;
  const minimumBottomInset: number = Math.max(24, (safeWidth * MIN_BOTTOM_INSET_RATIO) / density);
  const modeConfig: ModeLayoutConfig = resolveModeLayoutConfig(
    mode,
    safeHeight,
    viewportHeightVp
  );
  const calendarContentWidthRatio: number = modeConfig.calendarContentWidthRatio;
  const calendarGridWidthRatio: number = modeConfig.calendarGridWidthRatio;
  const calendarHorizontalPaddingVp: number = modeConfig.calendarHorizontalPaddingVp;
  const calendarInnerTopInsetRatio: number = modeConfig.calendarInnerTopInsetRatio;
  const calendarSelectorVerticalGapVp: number = modeConfig.calendarSelectorVerticalGapVp;
  const calendarGridRowGapVp: number = modeConfig.calendarGridRowGapVp;
  const calendarMonthCardTopInsetRatio: number = modeConfig.calendarMonthCardTopInsetRatio;
  const calendarGridHeightVp: number =
    (CALENDAR_DATE_ROW_COUNT * CALENDAR_DATE_ROW_HEIGHT_VP)
      + ((CALENDAR_DATE_ROW_COUNT - 1) * calendarGridRowGapVp);
  const calendarComponentWidthVp: number = viewportWidthVp
    * (mode === 'dual' ? DUAL_CALENDAR_COLUMN_WIDTH_RATIO : 1)
    * calendarContentWidthRatio;
  const calendarTitleFontSizeVp: number = clamp(
    CALENDAR_TITLE_BASELINE_FONT_SIZE_VP
      * calendarComponentWidthVp
      / PURA_X_SINGLE_CALENDAR_CONTENT_WIDTH_VP,
    CALENDAR_TITLE_MIN_FONT_SIZE_VP,
    CALENDAR_TITLE_MAX_FONT_SIZE_VP
  );
  const calendarTitleHeightVp: number = mode === 'compact'
    ? 0
    : calendarTitleFontSizeVp + CALENDAR_SUBTITLE_FONT_SIZE_VP + CALENDAR_TITLE_COLUMN_SPACE_VP;
  const calendarInnerTopInsetVp: number = calendarComponentWidthVp * calendarInnerTopInsetRatio;
  const calendarMonthCardTopInsetVp: number = mode === 'single'
    ? viewportWidthVp * SINGLE_CALENDAR_MONTH_CARD_TOP_INSET_RATIO
    : calendarComponentWidthVp * CALENDAR_MONTH_CARD_TOP_INSET_RATIO;
  const calendarGridContainerHeightVp: number = calendarGridHeightVp + calendarMonthCardTopInsetVp;
  const calendarRequiredHeightVp: number = calendarTitleHeightVp
    + calendarInnerTopInsetVp
    + CALENDAR_SELECTOR_HEIGHT_VP
    + calendarSelectorVerticalGapVp
    + calendarGridHeightVp
    + calendarMonthCardTopInsetVp;
  const maximumCalendarTopInsetVp: number = Math.max(
    0,
    contentHeight - calendarRequiredHeightVp - minimumBottomInset
  );
  const baselineTopInset: number = (safeHeight * PURA_X_SINGLE_TOP_INSET_RATIO) / density;
  const pageTopInset: number = clamp(
    baselineTopInset - safeTop / density,
    0,
    maximumCalendarTopInsetVp
  );
  const dualTopInset: number = clamp(
    (safeHeight * DUAL_CALENDAR_TOP_INSET_RATIO - safeTop) / density,
    0,
    maximumCalendarTopInsetVp
  );
  const scrollTopInset: number = clamp(
    (safeHeight * SCROLL_CALENDAR_TOP_INSET_RATIO - safeTop) / density,
    0,
    maximumCalendarTopInsetVp
  );
  const pageBottomInset: number = Math.max(
    minimumBottomInset,
    contentHeight - calendarRequiredHeightVp - pageTopInset
  );
  const compactTopInset: number = safeWidth * modeConfig.calendarTopInsetRatio;
  const calendarSelectorScale: number = clamp(
    calendarComponentWidthVp / PURA_X_SINGLE_CALENDAR_CONTENT_WIDTH_VP,
    0.82,
    1.12
  );
  const calendarYearButtonWidthVp: number = clamp(
    CALENDAR_YEAR_BUTTON_BASELINE_WIDTH_VP * calendarSelectorScale,
    CALENDAR_YEAR_BUTTON_MIN_WIDTH_VP,
    CALENDAR_YEAR_BUTTON_MAX_WIDTH_VP
  );
  const calendarMonthButtonWidthVp: number = clamp(
    CALENDAR_MONTH_BUTTON_BASELINE_WIDTH_VP * calendarSelectorScale,
    CALENDAR_MONTH_BUTTON_MIN_WIDTH_VP,
    CALENDAR_MONTH_BUTTON_MAX_WIDTH_VP
  );
  return {
    mode: mode,
    viewportWidth: safeWidth,
    viewportHeight: safeHeight,
    safeAreaTopInsetVp: safeTop / density,
    safeAreaBottomInsetVp: safeBottom / density,
    contentHeightVp: contentHeight,
    calendarTopInsetVp: mode === 'scroll'
      ? scrollTopInset
      : (mode === 'compact' ? compactTopInset : (mode === 'dual' ? dualTopInset : pageTopInset)),
    calendarBottomInsetVp: mode === 'compact'
      ? minimumBottomInset
      : (mode === 'scroll' ? 0 : pageBottomInset),
    calendarTopInsetRatio: modeConfig.calendarTopInsetRatio,
    calendarBottomInsetRatio: modeConfig.calendarBottomInsetRatio,
    calendarInnerTopInsetRatio: calendarInnerTopInsetRatio,
    calendarMonthCardTopInsetRatio: calendarMonthCardTopInsetRatio,
    calendarMonthCardTopInsetVp: calendarMonthCardTopInsetVp,
    calendarHorizontalPaddingVp: calendarHorizontalPaddingVp,
    calendarContentWidthRatio: calendarContentWidthRatio,
    calendarGridWidthRatio: calendarGridWidthRatio,
    calendarHeight: modeConfig.calendarHeight,
    calendarYearLabelShortThresholdVp: CALENDAR_YEAR_LABEL_SHORT_THRESHOLD_VP,
    calendarTitleFontSizeVp: calendarTitleFontSizeVp,
    calendarSubtitleFontSizeVp: CALENDAR_SUBTITLE_FONT_SIZE_VP,
    calendarSelectorVerticalGapVp: calendarSelectorVerticalGapVp,
    calendarSelectorHorizontalGapVp: 8,
    calendarSelectorHeightVp: CALENDAR_SELECTOR_HEIGHT_VP,
    calendarYearButtonWidthVp: calendarYearButtonWidthVp,
    calendarMonthButtonWidthVp: calendarMonthButtonWidthVp,
    calendarJumpPanelHeightVp: 183,
    calendarGridHeightVp: calendarGridHeightVp,
    calendarGridContainerHeightVp: calendarGridContainerHeightVp,
    calendarGridRowGapVp: calendarGridRowGapVp,
    calendarGridColumnGapVp: CALENDAR_GRID_COLUMN_GAP_VP,
    calendarDateSizeVp: CALENDAR_DATE_SIZE_VP,
    calendarDateRowHeightVp: CALENDAR_DATE_ROW_HEIGHT_VP,
    historyTopInsetRatio: modeConfig.historyTopInsetRatio,
    historyBottomInsetRatio: modeConfig.historyBottomInsetRatio,
    historySectionGapVp: HISTORY_SECTION_GAP_VP,
    scrollCalendarHistoryGapVp: modeConfig.scrollCalendarHistoryGapVp,
    scrollHistoryBottomInsetVp: modeConfig.scrollHistoryBottomInsetVp,
    historyShortBarThresholdRatio: HISTORY_SHORT_BAR_THRESHOLD_RATIO,
    historyShortBarOffsetVp: HISTORY_SHORT_BAR_OFFSET_VP,
    historyPredictionGapVp: 8,
    historyPeriodsGapVp: 14,
    compactHistoryContainerRatio: COMPACT_HISTORY_CONTAINER_RATIO,
    actionMenuCollapsedSizeVp: ACTION_MENU_COLLAPSED_SIZE_VP,
    actionMenuIconSizeVp: ACTION_MENU_ICON_SIZE_VP,
    actionMenuExpandedWidthVp: ACTION_MENU_EXPANDED_WIDTH_VP,
    actionMenuExpandedHeightVp: ACTION_MENU_EXPANDED_HEIGHT_VP,
    actionMenuItemHeightVp: ACTION_MENU_ITEM_HEIGHT_VP,
    actionMenuThemeRowHeightVp: ACTION_MENU_THEME_ROW_HEIGHT_VP,
    actionMenuThemeSwatchSizeVp: ACTION_MENU_THEME_SWATCH_SIZE_VP,
    actionMenuHorizontalPaddingVp: ACTION_MENU_HORIZONTAL_PADDING_VP,
    actionMenuVerticalPaddingVp: ACTION_MENU_VERTICAL_PADDING_VP,
    actionMenuCollapsedAnchorOffsetVp: ACTION_MENU_COLLAPSED_ANCHOR_OFFSET_VP,
    actionMenuExpandedAnchorOffsetYVp: ACTION_MENU_EXPANDED_ANCHOR_OFFSET_Y_VP,
    actionMenuRightInsetRatio: ACTION_MENU_RIGHT_INSET_RATIO,
    actionMenuBottomInsetRatio: ACTION_MENU_BOTTOM_INSET_RATIO,
    compactHistoryEnabled: modeConfig.compactHistoryEnabled,
    fixedActionMenu: modeConfig.fixedActionMenu
  };
}

function clamp(value: number, minimum: number, maximum: number): number {
  return Math.max(minimum, Math.min(maximum, value));
}

function isCompactWindow(width: number, height: number, ratio: number): boolean {
  return width <= COMPACT_MAX_DIMENSION
    && height <= COMPACT_MAX_DIMENSION
    && ratio >= COMPACT_MIN_RATIO
    && ratio <= COMPACT_MAX_RATIO;
}

function isDualWindow(width: number, height: number, ratio: number): boolean {
  // 标准 dual 比例直接进入双列；低分辨率不再覆盖比例判断。
  if (ratio >= DUAL_MIN_RATIO && ratio <= DUAL_MAX_RATIO) {
    return true;
  }
  // Mate X7 等大尺寸近方形窗口即使比例低于 1.3，也有足够宽度展示 dual。
  return width > 2000
    && height > 2000
    && ratio >= COMPACT_MIN_RATIO
    && ratio <= COMPACT_MAX_RATIO;
}

// 模式已经分类后，所有模式差异只在这里赋值；下方的公共计算只负责单位换算、
// 日历尺寸推导和安全区约束，避免组件通过条件重新判断运行时。
function resolveModeLayoutConfig(
  mode: PageLayoutMode,
  physicalHeight: number,
  viewportHeightVp: number
): ModeLayoutConfig {
  if (mode === 'compact') {
    return {
      calendarContentWidthRatio: 1,
      calendarGridWidthRatio: 1,
      calendarHorizontalPaddingVp: CALENDAR_PAGE_HORIZONTAL_PADDING_VP,
      calendarInnerTopInsetRatio: 0.04,
      calendarSelectorVerticalGapVp: 11,
      calendarGridRowGapVp: physicalHeight < COMPACT_MAX_DIMENSION ? 3 : 15,
      calendarMonthCardTopInsetRatio: CALENDAR_MONTH_CARD_TOP_INSET_RATIO,
      calendarTopInsetRatio: 0.03,
      calendarHeight: '100%',
      calendarBottomInsetRatio: 0.02,
      historyTopInsetRatio: HISTORY_TOP_INSET_RATIO,
      historyBottomInsetRatio: HISTORY_BOTTOM_INSET_RATIO,
      scrollCalendarHistoryGapVp: 0,
      scrollHistoryBottomInsetVp: 0,
      compactHistoryEnabled: true,
      fixedActionMenu: false
    };
  }
  if (mode === 'single') {
    return {
      calendarContentWidthRatio: CALENDAR_CONTENT_WIDTH_RATIO,
      calendarGridWidthRatio: CALENDAR_GRID_WIDTH_RATIO,
      calendarHorizontalPaddingVp: CALENDAR_PAGE_HORIZONTAL_PADDING_VP,
      calendarInnerTopInsetRatio: 0.04,
      calendarSelectorVerticalGapVp: 6,
      calendarGridRowGapVp: viewportHeightVp * SINGLE_CALENDAR_GRID_ROW_GAP_RATIO,
      calendarMonthCardTopInsetRatio: SINGLE_CALENDAR_MONTH_CARD_TOP_INSET_RATIO,
      calendarTopInsetRatio: PURA_X_SINGLE_TOP_INSET_RATIO,
      calendarHeight: '100%',
      calendarBottomInsetRatio: 0.02,
      historyTopInsetRatio: HISTORY_TOP_INSET_RATIO,
      historyBottomInsetRatio: HISTORY_BOTTOM_INSET_RATIO,
      scrollCalendarHistoryGapVp: 0,
      scrollHistoryBottomInsetVp: 0,
      compactHistoryEnabled: false,
      fixedActionMenu: false
    };
  }
  if (mode === 'dual') {
    return {
      calendarContentWidthRatio: CALENDAR_CONTENT_WIDTH_RATIO,
      calendarGridWidthRatio: CALENDAR_GRID_WIDTH_RATIO,
      calendarHorizontalPaddingVp: CALENDAR_PAGE_HORIZONTAL_PADDING_VP,
      calendarInnerTopInsetRatio: 0.04,
      calendarSelectorVerticalGapVp: 6,
      calendarGridRowGapVp: viewportHeightVp * DUAL_CALENDAR_GRID_ROW_GAP_RATIO,
      calendarMonthCardTopInsetRatio: CALENDAR_MONTH_CARD_TOP_INSET_RATIO,
      calendarTopInsetRatio: DUAL_CALENDAR_TOP_INSET_RATIO,
      calendarHeight: '100%',
      calendarBottomInsetRatio: 0.02,
      historyTopInsetRatio: HISTORY_TOP_INSET_RATIO,
      historyBottomInsetRatio: HISTORY_BOTTOM_INSET_RATIO,
      scrollCalendarHistoryGapVp: 0,
      scrollHistoryBottomInsetVp: 0,
      compactHistoryEnabled: false,
      fixedActionMenu: false
    };
  }
  return {
    calendarContentWidthRatio: 1,
    calendarGridWidthRatio: CALENDAR_GRID_WIDTH_RATIO,
    calendarHorizontalPaddingVp: SCROLL_CALENDAR_HORIZONTAL_PADDING_VP,
    calendarInnerTopInsetRatio: SCROLL_CALENDAR_INNER_TOP_INSET_RATIO,
    calendarSelectorVerticalGapVp: 6,
    calendarGridRowGapVp: SCROLL_CALENDAR_GRID_ROW_GAP_VP,
    calendarMonthCardTopInsetRatio: CALENDAR_MONTH_CARD_TOP_INSET_RATIO,
    calendarTopInsetRatio: SCROLL_CALENDAR_TOP_INSET_RATIO,
    calendarHeight: 'auto',
    calendarBottomInsetRatio: 0.02,
    historyTopInsetRatio: 0,
    historyBottomInsetRatio: HISTORY_BOTTOM_INSET_RATIO,
    scrollCalendarHistoryGapVp: 56,
    scrollHistoryBottomInsetVp: SCROLL_HISTORY_BOTTOM_INSET_VP,
    compactHistoryEnabled: false,
    fixedActionMenu: true
  };
}
