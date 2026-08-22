export type HistoryRowRecipe = {
  sourceTop: number;
  sourceHeight: number;
  targetTop: number;
  shiftAmount: number;
  revealStart: number;
  revealEnd: number;
};

const HISTORY_ROW_COUNT = 16;
const ROW_SOURCE_TOPS = Array.from({length: HISTORY_ROW_COUNT}, (_, index) => 208 + index * 116);
const ROW_REVEAL_STARTS = Array.from({length: HISTORY_ROW_COUNT}, (_, index) => 84 + index * 18);

export const HISTORY_ROWS: HistoryRowRecipe[] = ROW_SOURCE_TOPS.map((sourceTop, index) => ({
  sourceTop,
  sourceHeight: 116,
  targetTop: 282 + index * 41.5,
  shiftAmount: index < 8 ? 4 : 37.5,
  revealStart: ROW_REVEAL_STARTS[index],
  revealEnd: ROW_REVEAL_STARTS[index] + 14,
}));

export const HISTORY_FINAL_SHIFT = -HISTORY_ROWS.reduce((total, row) => total + row.shiftAmount, 0);
export const HISTORY_HEADER_SOURCE_BOTTOM = 744;
export const HISTORY_MASK_SOURCE_TOP = 840;
export const HISTORY_MASK_SOURCE_HEIGHT = 960;
export const HISTORY_MASK_BACKGROUND =
  'linear-gradient(to bottom, #ffebf0 0%, #ffebf0 48%, #ffffff 86%, #ffffff 100%)';
