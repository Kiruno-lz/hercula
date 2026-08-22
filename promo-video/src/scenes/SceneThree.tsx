import React from 'react';
import {AbsoluteFill, Easing, Img, interpolate, staticFile, useCurrentFrame} from 'remotion';
import {Backdrop} from '../components/Backdrop';
import {GlassFrame} from '../components/GlassFrame';
import {HISTORY_ROWS, HistoryRowRecipe} from '../historyRows';
import {segment} from '../motion';

export const SCENE_THREE_DURATION = 151;

const VIEWPORT = {left: 729, top: 174, width: 468, height: 686, radius: 28};
const SOURCE_WIDTH = 1320;
const PAGE_SCALE = VIEWPORT.width / SOURCE_WIDTH;
const PAGE_TOP = -117 * PAGE_SCALE;
const PAGE_HEIGHT = 2120 * PAGE_SCALE;
const PAGE_BACKGROUND = '#F8F3F3';
const EDGE_FEATHER = 3;
const FORECAST_VERTICAL_FEATHER = 7;
const HORIZONTAL_EDGE_MASK = `linear-gradient(90deg, transparent 0px, #000 ${EDGE_FEATHER}px, #000 calc(100% - ${EDGE_FEATHER}px), transparent 100%)`;
const CALENDAR_BOTTOM_EDGE_MASK = `linear-gradient(to top, transparent 0px, #000 ${EDGE_FEATHER}px, #000 100%)`;
const TITLE_TOP_EDGE_MASK = `linear-gradient(to bottom, transparent 0px, #000 ${EDGE_FEATHER}px, #000 100%)`;

const CALENDAR_IMAGE = staticFile('ui/first-stage-single-calendar.png');
const TITLE_IMAGE = staticFile('ui/title-lockup.png');
const EMPTY_HISTORY_IMAGE = staticFile('ui/history-empty-single-1320x2120-no-action.jpg');
const CLEAN_EMPTY_HISTORY_IMAGE = staticFile('ui/history-empty-single-1320x2120-clean.jpg');
const RECORDED_HISTORY_IMAGE = staticFile(
  'ui/history-recorded-sixteen-bottom-1320x2120-transparent.png',
);
const RECORDED_FORECAST_IMAGE = staticFile('ui/history-empty-single-1320x2120-clean-forecast.jpg');

const HISTORY_FADE_START = 56;
const HISTORY_FADE_END = 70;
const HISTORY_INTRO_START = 56;
const HISTORY_INTRO_STEP = 4;
const HISTORY_INTRO_DURATION = 10;
const HISTORY_SHIFT_LEAD = 4;
const HISTORY_SCROLL_OFFSET = -25;
const HISTORY_ROW_CROP_OFFSET = 8.7;
const HISTORY_FORECAST_START = 125;
const HISTORY_FORECAST_DURATION = 16;
export const HISTORY_FORECAST_SOURCE_TOP = 835;
export const HISTORY_FORECAST_SOURCE_HEIGHT = 120;

export const SCENE_THREE_HISTORY_PAGE_SHIFT = HISTORY_SCROLL_OFFSET;
export const SCENE_THREE_HISTORY_ROW_CROP_OFFSET = HISTORY_ROW_CROP_OFFSET;

export const SCENE_THREE_HISTORY_ROWS: HistoryRowRecipe[] = HISTORY_ROWS.map((row, index) => {
  const revealStart =
    HISTORY_INTRO_START + (HISTORY_ROWS.length - 1 - index) * HISTORY_INTRO_STEP;
  return {
    ...row,
    revealStart,
    revealEnd: revealStart + HISTORY_INTRO_DURATION,
  };
});

const CalendarPanel: React.FC = () => (
  <div
    style={{
      position: 'absolute',
      left: -VIEWPORT.left,
      top: -VIEWPORT.top,
      width: 1920,
      height: 1080,
    }}
  >
    <Img
      src={TITLE_IMAGE}
      style={{
        position: 'absolute',
        left: 850.5,
        top: 29,
        width: 667,
        height: 306,
        objectFit: 'contain',
        display: 'block',
        transform: 'scale(.705)',
        transformOrigin: 'center center',
        translate: '-220.6px 98.8px',
        borderRadius: '34px 34px 0 0',
        WebkitMaskImage: `${HORIZONTAL_EDGE_MASK}, ${TITLE_TOP_EDGE_MASK}`,
        maskImage: `${HORIZONTAL_EDGE_MASK}, ${TITLE_TOP_EDGE_MASK}`,
        WebkitMaskComposite: 'destination-in',
        maskComposite: 'intersect',
        WebkitMaskRepeat: 'no-repeat',
        maskRepeat: 'no-repeat',
      }}
    />
    <Img
      src={CALENDAR_IMAGE}
      style={{
        position: 'absolute',
        left: 605,
        top: 222.5,
        width: 720,
        height: 731,
        objectFit: 'cover',
        display: 'block',
        transform: 'translateY(60px) scale(.65)',
        transformOrigin: '355px 293px',
        borderRadius: '0 0 34px 34px',
        WebkitMaskImage: `${HORIZONTAL_EDGE_MASK}, ${CALENDAR_BOTTOM_EDGE_MASK}`,
        maskImage: `${HORIZONTAL_EDGE_MASK}, ${CALENDAR_BOTTOM_EDGE_MASK}`,
        WebkitMaskComposite: 'destination-in',
        maskComposite: 'intersect',
        WebkitMaskRepeat: 'no-repeat',
        maskRepeat: 'no-repeat',
      }}
    />
  </div>
);

const PeriodRowCutout: React.FC<{row: HistoryRowRecipe; pageShift: number}> = ({row, pageShift}) => {
  const frame = useCurrentFrame();
  const reveal = segment(frame, row.revealStart, row.revealEnd, Easing.out(Easing.cubic));
  const stripHeight = row.sourceHeight * PAGE_SCALE;
  const imageOffset = -row.sourceTop * PAGE_SCALE + HISTORY_ROW_CROP_OFFSET;

  return (
    <div
      style={{
        position: 'absolute',
        left: 0,
        top: row.targetTop + pageShift,
        width: VIEWPORT.width,
        height: stripHeight,
        overflow: 'hidden',
        opacity: reveal,
        transform: `translateX(${interpolate(reveal, [0, 1], [-28, 0])}px)`,
        clipPath: `inset(0 ${100 - reveal * 100}% 0 0)`,
      }}
    >
      <Img
        src={RECORDED_HISTORY_IMAGE}
        style={{
          position: 'absolute',
          left: 0,
          top: imageOffset,
          width: VIEWPORT.width,
          height: PAGE_HEIGHT,
          objectFit: 'fill',
          display: 'block',
        }}
      />
    </div>
  );
};

const HistoryForecastCutout: React.FC<{pageShift: number}> = ({pageShift}) => {
  const frame = useCurrentFrame();
  const reveal = segment(
    frame,
    HISTORY_FORECAST_START,
    HISTORY_FORECAST_START + HISTORY_FORECAST_DURATION,
    Easing.out(Easing.cubic),
  );
  const cropTop = PAGE_TOP + HISTORY_FORECAST_SOURCE_TOP * PAGE_SCALE + pageShift;

  return (
    <div
      style={{
        position: 'absolute',
        left: 0,
        top: cropTop,
        width: VIEWPORT.width,
        height: HISTORY_FORECAST_SOURCE_HEIGHT * PAGE_SCALE,
        overflow: 'hidden',
        opacity: reveal,
        WebkitMaskImage: `linear-gradient(to bottom, transparent 0px, #000 ${FORECAST_VERTICAL_FEATHER}px, #000 calc(100% - ${FORECAST_VERTICAL_FEATHER}px), transparent 100%)`,
        maskImage: `linear-gradient(to bottom, transparent 0px, #000 ${FORECAST_VERTICAL_FEATHER}px, #000 calc(100% - ${FORECAST_VERTICAL_FEATHER}px), transparent 100%)`,
        WebkitMaskRepeat: 'no-repeat',
        maskRepeat: 'no-repeat',
      }}
    >
      <Img
        src={RECORDED_FORECAST_IMAGE}
        style={{
          position: 'absolute',
          left: 0,
          top: -HISTORY_FORECAST_SOURCE_TOP * PAGE_SCALE,
          width: VIEWPORT.width,
          height: PAGE_HEIGHT,
          objectFit: 'fill',
          display: 'block',
        }}
      />
    </div>
  );
};

const HistoryPanel: React.FC = () => {
  const frame = useCurrentFrame();
  const emptyHistoryOpacity =
    1 - segment(frame, HISTORY_FADE_START, HISTORY_FADE_END, Easing.inOut(Easing.cubic));
  const pageShift = interpolate(
    segment(
      frame,
      HISTORY_INTRO_START - HISTORY_SHIFT_LEAD,
      HISTORY_INTRO_START,
      Easing.inOut(Easing.cubic),
    ),
    [0, 1],
    [0, HISTORY_SCROLL_OFFSET],
  );

  return (
    <div
      style={{
        position: 'absolute',
        inset: 0,
        width: VIEWPORT.width,
        height: VIEWPORT.height,
        overflow: 'hidden',
        borderRadius: VIEWPORT.radius,
        background: PAGE_BACKGROUND,
      }}
    >
      <div style={{position: 'absolute', inset: 0, transform: `translateY(${pageShift}px)`}}>
        <Img
          src={CLEAN_EMPTY_HISTORY_IMAGE}
          style={{
            position: 'absolute',
            left: 0,
            top: PAGE_TOP,
            width: VIEWPORT.width,
            height: PAGE_HEIGHT,
            objectFit: 'fill',
            display: 'block',
          }}
        />
        <Img
          src={EMPTY_HISTORY_IMAGE}
          style={{
            position: 'absolute',
            left: 0,
            top: PAGE_TOP+3,
            width: VIEWPORT.width,
            height: PAGE_HEIGHT,
            objectFit: 'fill',
            display: 'block',
            opacity: emptyHistoryOpacity,
          }}
        />
      </div>
      {SCENE_THREE_HISTORY_ROWS.map((row) => (
        <PeriodRowCutout key={row.sourceTop} row={row} pageShift={pageShift} />
      ))}
      <HistoryForecastCutout pageShift={pageShift} />
    </div>
  );
};

export const SceneThree: React.FC = () => {
  const frame = useCurrentFrame();
  const swipe = segment(frame, 14, 56, Easing.inOut(Easing.cubic));

  return (
    <AbsoluteFill>
      <Backdrop accent="#D77F91" />
      <AbsoluteFill>
        <GlassFrame left={708} top={153} width={510} height={733} radius={34} />
      </AbsoluteFill>
      <div
        style={{
          position: 'absolute',
          left: VIEWPORT.left,
          top: VIEWPORT.top,
          width: VIEWPORT.width,
          height: VIEWPORT.height,
          overflow: 'hidden',
          borderRadius: VIEWPORT.radius,
        }}
      >
        <div
          style={{
            position: 'absolute',
            inset: 0,
            transform: `translateY(${-VIEWPORT.height * swipe}px)`,
          }}
        >
          <CalendarPanel />
        </div>
        <div
          style={{
            position: 'absolute',
            inset: 0,
            transform: `translateY(${VIEWPORT.height * (1 - swipe)}px)`,
          }}
        >
          <HistoryPanel />
        </div>
      </div>
    </AbsoluteFill>
  );
};
