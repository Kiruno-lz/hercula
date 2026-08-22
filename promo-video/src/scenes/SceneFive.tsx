import React from 'react';
import {AbsoluteFill, Easing, Img, interpolate, staticFile, useCurrentFrame} from 'remotion';
import {Backdrop} from '../components/Backdrop';
import {GlassFrame} from '../components/GlassFrame';
import {fade, segment} from '../motion';

export const SCENE_FIVE_DURATION = 100;

const COMPACT_IMAGE = staticFile('ui/calendar-recorded-compact-980x980.jpg');
const MARKER_COLOR = '#CF7F90';
const MASK_CENTER = {x: 960, y: 593.5};
const COMPACT_GLASS = {left: 735, top: 370, width: 450, height: 460, radius: 34};
const COMPACT_CONTENT = {left: 760, top: 400, width: 400, height: 400};
const MARKER_SIZE = 46;
const COMPACT_REMOVE_START = -20;
const COMPACT_REMOVE_DURATION = 52;
const MARKER_REMOVE_DELAY = 5;

const CompactCalendar: React.FC<{mask: string}> = ({mask}) => (
  <AbsoluteFill
    style={{
      WebkitMaskImage: mask,
      maskImage: mask,
      WebkitMaskRepeat: 'no-repeat',
      maskRepeat: 'no-repeat',
    }}
  >
    <AbsoluteFill>
      <GlassFrame {...COMPACT_GLASS} />
    </AbsoluteFill>
    <Img
      src={COMPACT_IMAGE}
      style={{
        position: 'absolute',
        left: COMPACT_CONTENT.left,
        top: COMPACT_CONTENT.top,
        width: COMPACT_CONTENT.width,
        height: COMPACT_CONTENT.height,
        objectFit: 'fill',
        display: 'block',
        borderRadius: 28,
      }}
    />
  </AbsoluteFill>
);

const MarkerButton: React.FC = () => (
  <div
    style={{
      position: 'absolute',
      left: MASK_CENTER.x - MARKER_SIZE / 2,
      top: MASK_CENTER.y - MARKER_SIZE / 2,
      width: MARKER_SIZE,
      height: MARKER_SIZE,
      borderRadius: '50%',
      background: MARKER_COLOR,
      color: '#FFFFFF',
      fontFamily: 'HarmonyOS Sans SC, HarmonyOS Sans, sans-serif',
      fontSize: 20,
      fontWeight: 300,
      lineHeight: '32px',
      textAlign: 'center',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
    }}
  >
    <span style={{transform: 'translateY(1px)'}}>11</span>
  </div>
);

const ClosingMessage: React.FC = () => {
  const frame = useCurrentFrame();
  const progress = fade(frame, 36, 62);
  const translateY = interpolate(progress, [0, 1], [18, 0]);

  return (
    <AbsoluteFill
      style={{
        alignItems: 'center',
        justifyContent: 'center',
        opacity: progress,
        transform: `translateY(${translateY}px)`,
        fontFamily: 'HarmonyOS Sans SC, HarmonyOS Sans, sans-serif',
        color: '#4E5F57',
        textAlign: 'center',
      }}
    >
      <div style={{fontSize: 68, lineHeight: 1.28, fontWeight: 650, letterSpacing: -1}}>
        简单记，月月迹，更懂你
      </div>
      <div
        style={{
          marginTop: 28,
          fontSize: 36,
          lineHeight: 1.2,
          fontWeight: 450,
          letterSpacing: 5,
          color: '#B86478',
        }}
      >
        月迹 · hercula
      </div>
    </AbsoluteFill>
  );
};

export const SceneFive: React.FC = () => {
  const frame = useCurrentFrame();
  const imageContraction = segment(
    frame,
    COMPACT_REMOVE_START,
    COMPACT_REMOVE_START + COMPACT_REMOVE_DURATION,
    Easing.inOut(Easing.cubic),
  );
  const markerContraction = segment(
    frame,
    COMPACT_REMOVE_START + MARKER_REMOVE_DELAY,
    COMPACT_REMOVE_START + MARKER_REMOVE_DELAY + COMPACT_REMOVE_DURATION,
    Easing.inOut(Easing.cubic),
  );
  const imageRadius = interpolate(imageContraction, [0, 1], [1450, 0]);
  const markerRadius = interpolate(markerContraction, [0, 1], [1450, 0]);
  const imageHardEdge = Math.max(0, imageRadius - 16);
  const markerHardEdge = Math.max(0, markerRadius - 16);
  const imageMask = `radial-gradient(circle at ${MASK_CENTER.x}px ${MASK_CENTER.y}px, #000 0px, #000 ${imageHardEdge}px, transparent ${imageRadius}px)`;
  const markerMask = `radial-gradient(circle at ${MASK_CENTER.x}px ${MASK_CENTER.y}px, #000 0px, #000 ${markerHardEdge}px, transparent ${markerRadius}px)`;

  return (
    <AbsoluteFill>
      <Backdrop accent="#D77F91" />
      <CompactCalendar mask={imageMask} />
      <AbsoluteFill
        style={{
          WebkitMaskImage: markerMask,
          maskImage: markerMask,
          WebkitMaskRepeat: 'no-repeat',
          maskRepeat: 'no-repeat',
        }}
      >
        <MarkerButton />
      </AbsoluteFill>
      <ClosingMessage />
    </AbsoluteFill>
  );
};
