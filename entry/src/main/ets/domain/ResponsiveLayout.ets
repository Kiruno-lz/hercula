export type PageLayoutMode = 'compact' | 'single' | 'dual' | 'scroll';

const COMPACT_MAX_DIMENSION: number = 1000;
const COMPACT_MIN_RATIO: number = 0.82;
const COMPACT_MAX_RATIO: number = 1.22;
const SCROLL_MAX_RATIO: number = 0.6;
const DUAL_MIN_RATIO: number = 1.3;
const DUAL_MAX_RATIO: number = 1.8;

/**
 * Classify the page from the complete window rectangle.
 * The caller must provide windowRect.width and windowRect.height, not the
 * drawable content area after system safe-area insets.
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
