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
  calendarHorizontalPaddingVp: number;
  calendarContentWidthRatio: number;
  calendarGridWidthRatio: number;
  calendarTitleFontSizeVp: number;
  calendarSubtitleFontSizeVp: number;
  calendarSelectorVerticalGapVp: number;
  calendarSelectorHorizontalGapVp: number;
  calendarSelectorHeightVp: number;
  calendarYearButtonWidthVp: number;
  calendarMonthButtonWidthVp: number;
  calendarJumpPanelHeightVp: number;
  calendarGridHeightVp: number;
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
  actionMenuCollapsedSizeVp: number;
  actionMenuIconSizeVp: number;
  actionMenuExpandedWidthVp: number;
  actionMenuExpandedHeightVp: number;
  actionMenuItemHeightVp: number;
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
// 需要整体移动 single/dual/scroll 的日历时，优先调整下面的 0.35：
// - 减小：日历整体上移；增大：日历整体下移。
// 该值作用于 full window height，后续会扣除安全区并从 px 转换为 vp。
const PURA_X_SINGLE_BASELINE_WIDTH: number = 1320;
const PURA_X_SINGLE_BASELINE_HEIGHT: number = 2120;
const PURA_X_SINGLE_BASELINE_TOP_INSET: number = PURA_X_SINGLE_BASELINE_WIDTH * 0.35;
const PURA_X_SINGLE_TOP_INSET_RATIO: number =
  PURA_X_SINGLE_BASELINE_TOP_INSET / PURA_X_SINGLE_BASELINE_HEIGHT;

// CalendarComponent 内部主内容列宽约占组件宽度的 85%。
// dual 时 CalendarComponent 位于左右两列之一，因此还要乘以 50%。
// 标题字号使用 Pura X single 的 68vp 作为上限基线，按实际内容列宽缩放。
const CALENDAR_CONTENT_WIDTH_RATIO: number = 0.85;
const CALENDAR_GRID_WIDTH_RATIO: number = 0.92;
const CALENDAR_PAGE_HORIZONTAL_PADDING_VP: number = 20;
// scroll 下只修改下面四个数值即可微调对应视觉参数；各值仍会经过完整窗口和安全区换算。
const SCROLL_CALENDAR_TOP_INSET_RATIO: number = 0.12;
const SCROLL_CALENDAR_HORIZONTAL_PADDING_VP: number = 17;
const SCROLL_CALENDAR_INNER_TOP_INSET_RATIO: number = 0.12;
const SCROLL_CALENDAR_GRID_ROW_GAP_VP: number = 3;
const SCROLL_CALENDAR_DATE_ROW_COUNT: number = 5;
const CALENDAR_DATE_ROW_HEIGHT_VP: number = 40;
const SCROLL_HISTORY_BOTTOM_INSET_VP: number = 64;
const HISTORY_SHORT_BAR_THRESHOLD_RATIO: number = 0.05;
const HISTORY_SHORT_BAR_OFFSET_VP: number = 3;
const DUAL_CALENDAR_COLUMN_WIDTH_RATIO: number = 0.5;
const PURA_X_SINGLE_BASELINE_DENSITY_PIXELS: number = 3;
const PURA_X_SINGLE_CALENDAR_CONTENT_WIDTH_VP: number =
  (PURA_X_SINGLE_BASELINE_WIDTH / PURA_X_SINGLE_BASELINE_DENSITY_PIXELS)
    * CALENDAR_CONTENT_WIDTH_RATIO;
const CALENDAR_TITLE_BASELINE_FONT_SIZE_VP: number = 68;
const CALENDAR_TITLE_MIN_FONT_SIZE_VP: number = 48;
const CALENDAR_TITLE_MAX_FONT_SIZE_VP: number = 68;
// 所有运行时统一调整 ActionMenu 的右、下边缘留白；只修改下面两个百分比数值。
const ACTION_MENU_RIGHT_INSET_RATIO: number = 0.08;
const ACTION_MENU_BOTTOM_INSET_RATIO: number = 0.08;
// 年份按钮的文本是“2026年”，必须保留单行完整显示；月份按钮保留独立的较小下限。
// 宽屏按基线比例增长，窄屏不低于最小可用宽度，避免 Button 内部压缩文字。
const CALENDAR_YEAR_BUTTON_BASELINE_WIDTH_VP: number = 86;
const CALENDAR_MONTH_BUTTON_BASELINE_WIDTH_VP: number = 58;
const CALENDAR_YEAR_BUTTON_MIN_WIDTH_VP: number = 82;
const CALENDAR_MONTH_BUTTON_MIN_WIDTH_VP: number = 54;
const CALENDAR_YEAR_BUTTON_MAX_WIDTH_VP: number = 96;
const CALENDAR_MONTH_BUTTON_MAX_WIDTH_VP: number = 66;
const CALENDAR_INTRINSIC_HEIGHT_VP: number = 551;
const MIN_BOTTOM_INSET_RATIO: number = 0.02;

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
  if (isStandardDualWindow(width, height, ratio) || isLargeNearSquareLandscape(width, height, ratio)) {
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

  // 顶部留白的实际控制值是 calendarTopInsetVp，不是 calendarTopInsetRatio。
  // single/dual/scroll 共用 Pura X 基线；compact 使用独立的紧凑顶部策略。
  const minimumBottomInset: number = Math.max(24, (safeWidth * MIN_BOTTOM_INSET_RATIO) / density);
  const baselineTopInset: number = (safeHeight * PURA_X_SINGLE_TOP_INSET_RATIO) / density;
  const pageTopInset: number = clamp(
    baselineTopInset - (safeTop / density),
    0,
    Math.max(0, contentHeight - CALENDAR_INTRINSIC_HEIGHT_VP - minimumBottomInset)
  );
  const scrollTopInset: number = clamp(
    (safeHeight * SCROLL_CALENDAR_TOP_INSET_RATIO - safeTop) / density,
    0,
    Math.max(0, contentHeight - CALENDAR_INTRINSIC_HEIGHT_VP - minimumBottomInset)
  );
  const pageBottomInset: number = Math.max(
    minimumBottomInset,
    contentHeight - CALENDAR_INTRINSIC_HEIGHT_VP - pageTopInset
  );
  const compactTopInset: number = safeWidth * 0.03;
  const viewportWidthVp: number = safeWidth / density;
  // compact 使用完整网格宽度；scroll 和其他运行时保持原有比例，避免改变已验收的网格布局。
  const calendarContentWidthRatio: number = mode === 'compact' || mode === 'scroll'
    ? 1
    : CALENDAR_CONTENT_WIDTH_RATIO;
  const calendarGridWidthRatio: number = mode === 'compact' ? 1 : CALENDAR_GRID_WIDTH_RATIO;
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
      : (mode === 'compact' ? compactTopInset : pageTopInset),
    calendarBottomInsetVp: mode === 'compact'
      ? minimumBottomInset
      : (mode === 'scroll' ? 0 : pageBottomInset),
    // 这些 Ratio 字段用于表达设计基线；实际移动组件请调整上面的
    // calendarTopInsetVp / compactTopInset，不要只改这个记录字段。
    calendarTopInsetRatio: mode === 'scroll'
      ? SCROLL_CALENDAR_TOP_INSET_RATIO
      : (mode === 'compact' ? 0.03 : 0.25),
    calendarBottomInsetRatio: 0.02,
    calendarInnerTopInsetRatio: mode === 'scroll'
      ? SCROLL_CALENDAR_INNER_TOP_INSET_RATIO
      : 0.04,
    calendarMonthCardTopInsetRatio: 0.0167,
    // scroll 标题顶部由 calendarTopInsetVp 控制，左侧由该 padding 控制。
    // 日期网格使用独立宽度比，避免 compact/scroll 的标记圆形被列宽裁切。
    calendarHorizontalPaddingVp: mode === 'scroll'
      ? SCROLL_CALENDAR_HORIZONTAL_PADDING_VP
      : CALENDAR_PAGE_HORIZONTAL_PADDING_VP,
    calendarContentWidthRatio: calendarContentWidthRatio,
    calendarGridWidthRatio: calendarGridWidthRatio,
    // compact 不渲染标题；其顶部位置由 compactTopInset 单独控制。
    // 其他模式根据日历内容列宽缩放标题，避免窄屏 scroll/dual 挤压标题。
    calendarTitleFontSizeVp: calendarTitleFontSizeVp,
    calendarSubtitleFontSizeVp: 24,
    calendarSelectorVerticalGapVp: mode === 'compact' ? 11 : 6,
    calendarSelectorHorizontalGapVp: 8,
    calendarSelectorHeightVp: 38,
    calendarYearButtonWidthVp: calendarYearButtonWidthVp,
    calendarMonthButtonWidthVp: calendarMonthButtonWidthVp,
    calendarJumpPanelHeightVp: 183,
    // scroll 日历没有星期标题，高度随行距变化：5 行日期 + 4 个行间距。
    // single/dual 保持原有 360vp 的呼吸感，compact 也保留自身画布高度。
    calendarGridHeightVp: mode === 'scroll'
      ? (SCROLL_CALENDAR_DATE_ROW_COUNT * CALENDAR_DATE_ROW_HEIGHT_VP)
        + ((SCROLL_CALENDAR_DATE_ROW_COUNT - 1) * SCROLL_CALENDAR_GRID_ROW_GAP_VP)
      : 360,
    // 仅 compact 小画布压缩日期行；single/dual/scroll 保持已验收的 15vp。
    calendarGridRowGapVp: mode === 'scroll'
      ? SCROLL_CALENDAR_GRID_ROW_GAP_VP
      : (mode === 'compact' && safeHeight < COMPACT_MAX_DIMENSION ? 3 : 15),
    calendarGridColumnGapVp: 2,
    calendarDateSizeVp: 38,
    calendarDateRowHeightVp: CALENDAR_DATE_ROW_HEIGHT_VP,
    historyTopInsetRatio: mode === 'scroll' ? 0 : 0.0212,
    historyBottomInsetRatio: 0.0152,
    historySectionGapVp: 16,
    scrollCalendarHistoryGapVp: mode === 'scroll' ? 56 : 0,
    scrollHistoryBottomInsetVp: mode === 'scroll' ? SCROLL_HISTORY_BOTTOM_INSET_VP : 0,
    historyShortBarThresholdRatio: HISTORY_SHORT_BAR_THRESHOLD_RATIO,
    historyShortBarOffsetVp: HISTORY_SHORT_BAR_OFFSET_VP,
    historyPredictionGapVp: 8,
    historyPeriodsGapVp: 14,
    actionMenuCollapsedSizeVp: 44,
    actionMenuIconSizeVp: 24,
    actionMenuExpandedWidthVp: 184,
    actionMenuExpandedHeightVp: 172,
    actionMenuItemHeightVp: 40,
    actionMenuHorizontalPaddingVp: 18,
    actionMenuVerticalPaddingVp: 16,
    actionMenuCollapsedAnchorOffsetVp: 140,
    actionMenuExpandedAnchorOffsetYVp: -128,
    actionMenuRightInsetRatio: ACTION_MENU_RIGHT_INSET_RATIO,
    actionMenuBottomInsetRatio: ACTION_MENU_BOTTOM_INSET_RATIO,
    compactHistoryEnabled: mode === 'compact',
    fixedActionMenu: mode === 'scroll'
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

function isStandardDualWindow(width: number, height: number, ratio: number): boolean {
  return width > COMPACT_MAX_DIMENSION
    && height > COMPACT_MAX_DIMENSION
    && ratio >= DUAL_MIN_RATIO
    && ratio <= DUAL_MAX_RATIO;
}

function isLargeNearSquareLandscape(width: number, height: number, ratio: number): boolean {
  return width > COMPACT_MAX_DIMENSION
    && height > COMPACT_MAX_DIMENSION
    && width > height
    && ratio >= COMPACT_MIN_RATIO
    && ratio <= COMPACT_MAX_RATIO;
}
