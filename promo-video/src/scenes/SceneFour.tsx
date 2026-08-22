import React from 'react';
import {AbsoluteFill, Easing, Img, interpolate, staticFile, useCurrentFrame} from 'remotion';
import {Backdrop} from '../components/Backdrop';
import {GlassFrame, GlassFrameGeometry} from '../components/GlassFrame';
import {
  HISTORY_FORECAST_SOURCE_HEIGHT,
  HISTORY_FORECAST_SOURCE_TOP,
  SCENE_THREE_HISTORY_PAGE_SHIFT,
  SCENE_THREE_HISTORY_ROW_CROP_OFFSET,
  SCENE_THREE_HISTORY_ROWS,
} from './SceneThree';
import {segment} from '../motion';

export const SCENE_FOUR_DURATION = 172;

type ContentGeometry = GlassFrameGeometry;

const SINGLE_GLASS: GlassFrameGeometry = {left: 708, top: 153, width: 510, height: 733, radius: 34};
const DUAL_GLASS: GlassFrameGeometry = {left: 335, top: 142, width: 1250, height: 786, radius: 34};
const SCROLL_GLASS: GlassFrameGeometry = {left: 735, top: 75, width: 450, height: 910, radius: 34};
const COMPACT_GLASS: GlassFrameGeometry = {left: 735, top: 370, width: 450, height: 460, radius: 34};

const SINGLE_CONTENT: ContentGeometry = {left: 729, top: 174, width: 468, height: 686, radius: 34};
const DUAL_CONTENT: ContentGeometry = {left: 360, top: 160, width: 1200, height: 747, radius: 28};
const SCROLL_CONTENT: ContentGeometry = {left: 760, top: 95, width: 400, height: 866, radius: 28};
const COMPACT_CONTENT: ContentGeometry = {left: 760, top: 400, width: 400, height: 400, radius: 28};

const SOURCE_WIDTH = 1320;
const SINGLE_SCALE = SINGLE_CONTENT.width / SOURCE_WIDTH;
const SINGLE_PAGE_TOP = -117 * SINGLE_SCALE;
const SINGLE_PAGE_HEIGHT = 2120 * SINGLE_SCALE;
const SINGLE_PAGE_SHIFT = SCENE_THREE_HISTORY_PAGE_SHIFT;
const PAGE_BACKGROUND = '#F8F3F3';

const CLEAN_EMPTY_HISTORY_IMAGE = staticFile('ui/history-empty-single-1320x2120-clean.jpg');
const CLEAN_FORECAST_IMAGE = staticFile('ui/history-empty-single-1320x2120-clean-forecast.jpg');
const RECORDED_HISTORY_IMAGE = staticFile(
  'ui/history-recorded-sixteen-bottom-1320x2120-transparent.png',
);
const DUAL_IMAGE = staticFile('ui/calendar-recorded-dual-2120x1320.jpg');
const SCROLL_IMAGE = staticFile('ui/calendar-recorded-scroll-1320x2856.jpg');
const COMPACT_IMAGE = staticFile('ui/calendar-recorded-compact-980x980.jpg');

const morphGeometry = (
  frame: number,
  start: number,
  end: number,
  from: GlassFrameGeometry,
  to: GlassFrameGeometry,
): GlassFrameGeometry => {
  const progress = segment(frame, start, end, Easing.inOut(Easing.cubic));
  const value = (a: number, b: number) => interpolate(progress, [0, 1], [a, b]);
  return {
    left: value(from.left, to.left),
    top: value(from.top, to.top),
    width: value(from.width, to.width),
    height: value(from.height, to.height),
    radius: value(from.radius, to.radius),
  };
};

const currentGeometry = (
  frame: number,
  single: GlassFrameGeometry,
  dual: GlassFrameGeometry,
  scroll: GlassFrameGeometry,
  compact: GlassFrameGeometry,
) => {
  if (frame < 50) return morphGeometry(frame, 14, 50, single, dual);
  if (frame < 108) return morphGeometry(frame, 72, 108, dual, scroll);
  return morphGeometry(frame, 128, 164, scroll, compact);
};

const blurDuringMorph = (frame: number, start: number, end: number) => {
  const progress = segment(frame, start, end, Easing.linear);
  return Math.sin(progress * Math.PI) * 14;
};

const SingleHistorySnapshot: React.FC<{width: number; height: number}> = ({width, height}) => (
  <div
    style={{
      position: 'absolute',
      left: 0,
      top: 0,
      width: SINGLE_CONTENT.width,
      height: SINGLE_CONTENT.height,
      transform: `scale(${width / SINGLE_CONTENT.width}, ${height / SINGLE_CONTENT.height})`,
      transformOrigin: 'top left',
      background: PAGE_BACKGROUND,
    }}
  >
    <div
      style={{
        position: 'absolute',
        inset: 0,
        transform: `translateY(${SINGLE_PAGE_SHIFT}px)`,
      }}
    >
      <Img
        src={CLEAN_EMPTY_HISTORY_IMAGE}
        style={{
          position: 'absolute',
          left: 0,
          top: SINGLE_PAGE_TOP,
          width: SINGLE_CONTENT.width,
          height: SINGLE_PAGE_HEIGHT,
          objectFit: 'fill',
          display: 'block',
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: 0,
          top: SINGLE_PAGE_TOP + HISTORY_FORECAST_SOURCE_TOP * SINGLE_SCALE,
          width: SINGLE_CONTENT.width,
          height: HISTORY_FORECAST_SOURCE_HEIGHT * SINGLE_SCALE,
          overflow: 'hidden',
        }}
      >
        <Img
          src={CLEAN_FORECAST_IMAGE}
          style={{
            position: 'absolute',
            left: 0,
            top: -HISTORY_FORECAST_SOURCE_TOP * SINGLE_SCALE,
            width: SINGLE_CONTENT.width,
            height: SINGLE_PAGE_HEIGHT,
            objectFit: 'fill',
            display: 'block',
          }}
        />
      </div>
    </div>
    {SCENE_THREE_HISTORY_ROWS.map((row) => (
      <div
        key={row.sourceTop}
        style={{
          position: 'absolute',
          left: 0,
          top: row.targetTop + SINGLE_PAGE_SHIFT,
          width: SINGLE_CONTENT.width,
          height: row.sourceHeight * SINGLE_SCALE,
          overflow: 'hidden',
        }}
      >
        <Img
          src={RECORDED_HISTORY_IMAGE}
          style={{
            position: 'absolute',
            left: 0,
            top: -row.sourceTop * SINGLE_SCALE + SCENE_THREE_HISTORY_ROW_CROP_OFFSET,
            width: SINGLE_CONTENT.width,
            height: SINGLE_PAGE_HEIGHT,
            objectFit: 'fill',
            display: 'block',
          }}
        />
      </div>
    ))}
  </div>
);

const RuntimeImage: React.FC<{src: string; opacity: number}> = ({src, opacity}) => (
  <Img
    src={src}
    style={{
      position: 'absolute',
      inset: 0,
      width: '100%',
      height: '100%',
      objectFit: 'fill',
      display: 'block',
      opacity,
    }}
  />
);

export const SceneFour: React.FC = () => {
  const frame = useCurrentFrame();
  const glass = currentGeometry(frame, SINGLE_GLASS, DUAL_GLASS, SCROLL_GLASS, COMPACT_GLASS);
  const content = currentGeometry(
    frame,
    SINGLE_CONTENT,
    DUAL_CONTENT,
    SCROLL_CONTENT,
    COMPACT_CONTENT,
  );
  const blur =
    blurDuringMorph(frame, 14, 50) +
    blurDuringMorph(frame, 72, 108) +
    blurDuringMorph(frame, 128, 164);
  const singleOpacity = 1 - segment(frame, 28, 42, Easing.inOut(Easing.cubic));
  const dualOpacity = Math.min(
    segment(frame, 28, 42, Easing.inOut(Easing.cubic)),
    1 - segment(frame, 86, 100, Easing.inOut(Easing.cubic)),
  );
  const scrollOpacity = Math.min(
    segment(frame, 86, 100, Easing.inOut(Easing.cubic)),
    1 - segment(frame, 142, 156, Easing.inOut(Easing.cubic)),
  );
  const compactOpacity = segment(frame, 142, 156, Easing.inOut(Easing.cubic));
  const dayElevenOpacity = segment(frame, 250, 264, Easing.inOut(Easing.cubic));

  return (
    <AbsoluteFill>
      <Backdrop accent="#D77F91" />
      <AbsoluteFill>
        <GlassFrame {...glass} />
      </AbsoluteFill>
      <div
        style={{
          position: 'absolute',
          left: content.left,
          top: content.top,
          width: content.width,
          height: content.height,
          overflow: 'hidden',
          borderRadius: content.radius,
          filter: `blur(${blur}px)`,
          background: PAGE_BACKGROUND,
        }}
      >
        <div style={{position: 'absolute', inset: 0, opacity: singleOpacity}}>
          <SingleHistorySnapshot width={content.width} height={content.height} />
        </div>
        <RuntimeImage src={DUAL_IMAGE} opacity={dualOpacity} />
        <RuntimeImage src={SCROLL_IMAGE} opacity={scrollOpacity} />
        <RuntimeImage src={COMPACT_IMAGE} opacity={compactOpacity} />
        <div
          style={{
            position: 'absolute',
            inset: 0,
            background: 'rgba(255,255,255,.16)',
            opacity: Math.min(1, blur / 14) * 0.5,
          }}
        />
      </div>
      <div
        style={{
          position: 'absolute',
          left: 937,
          top: 570.5,
          width: 46,
          height: 46,
          borderRadius: '50%',
          background: '#CF7F90',
          color: '#FFFFFF',
          fontFamily: 'HarmonyOS Sans SC, HarmonyOS Sans, sans-serif',
          fontSize: 20,
          fontWeight: 300,
          lineHeight: '32px',
          textAlign: 'center',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          opacity: compactOpacity * dayElevenOpacity,
        }}
      >
        <span style={{transform: 'translateY(1px)'}}>11</span>
      </div>
    </AbsoluteFill>
  );
};
