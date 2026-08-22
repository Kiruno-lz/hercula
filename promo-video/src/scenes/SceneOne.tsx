import React from 'react';
import {
  AbsoluteFill,
  Easing,
  Img,
  Sequence,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
} from 'remotion';
import {Backdrop} from '../components/Backdrop';
import {GlassFrame} from '../components/GlassFrame';
import {fade, segment} from '../motion';

export const SCENE_ONE_DURATION = 111;

const MARKER_COLOR = '#D77F91';
const CALENDAR_IMAGE = staticFile('ui/first-stage-single-calendar.png');
const TITLE_IMAGE = staticFile('ui/title-lockup.png');

const MarkerTrack: React.FC = () => {
  const frame = useCurrentFrame();
  const opacity = 1 - segment(frame, 55, 67, Easing.inOut(Easing.cubic));
  const labelOpacity = fade(frame, 30, 50);

  return (
    <AbsoluteFill>
      <div
        style={{
          position: 'absolute',
          left: 936,
          top: 492,
          width: 48,
          height: 48,
          borderRadius: '50%',
          background: MARKER_COLOR,
          opacity,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        <span
          style={{
            opacity: labelOpacity,
            color: '#FFFFFF',
            fontFamily: 'HarmonyOS Sans SC, HarmonyOS Sans, sans-serif',
            fontSize: 20,
            lineHeight: 1,
            fontWeight: 500,
          }}
        >
          11
        </span>
      </div>
    </AbsoluteFill>
  );
};

const GlassTrack: React.FC = () => {
  const frame = useCurrentFrame();
  const progress = fade(frame, 0, 14);

  return (
    <AbsoluteFill>
      <GlassFrame
        left={708}
        top={153}
        width={510}
        height={733}
        radius={34}
        opacity={progress}
        scale={interpolate(progress, [0, 1], [0.985, 1])}
      />
    </AbsoluteFill>
  );
};

const CalendarTrack: React.FC = () => {
  const frame = useCurrentFrame();
  const reveal = segment(frame, 0, 86, Easing.inOut(Easing.cubic));
  const radius = interpolate(reveal, [0, 1], [20, 1320]);
  const revealMask = `radial-gradient(circle at 355px 293px, #000 0px, #000 ${radius}px, transparent ${radius + 1}px)`;
  const edgeFeather = 3;
  const horizontalEdgeMask = `linear-gradient(90deg, transparent 0px, #000 ${edgeFeather}px, #000 calc(100% - ${edgeFeather}px), transparent 100%)`;
  const bottomEdgeMask = `linear-gradient(to top, transparent 0px, #000 ${edgeFeather}px, #000 100%)`;
  const shiftFrame = frame - 33;
  const calendarShift =
    shiftFrame < 0
      ? 0
      : spring({
          frame: shiftFrame,
          fps: 30,
          config: {damping: 20, stiffness: 100, mass: 1, overshootClamping: true},
          from: 0,
          to: 60,
          durationInFrames: 15,
        });

  return (
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
        transform: `translateY(${calendarShift}px) scale(.65)`,
        transformOrigin: '355px 293px',
        borderRadius: '0 0 34px 34px',
        WebkitMaskImage: `${revealMask}, ${horizontalEdgeMask}, ${bottomEdgeMask}`,
        maskImage: `${revealMask}, ${horizontalEdgeMask}, ${bottomEdgeMask}`,
        WebkitMaskComposite: 'destination-in, destination-in',
        maskComposite: 'intersect, intersect',
        WebkitMaskRepeat: 'no-repeat',
        maskRepeat: 'no-repeat',
      }}
    />
  );
};

const TitleTrack: React.FC = () => {
  const frame = useCurrentFrame();
  const progress = fade(frame, 0, 20);
  const translateY = interpolate(progress, [0, 1], [18, 0]);
  const edgeFeather = 3;
  const horizontalEdgeMask = `linear-gradient(90deg, transparent 0px, #000 ${edgeFeather}px, #000 calc(100% - ${edgeFeather}px), transparent 100%)`;
  const topEdgeMask = `linear-gradient(to bottom, transparent 0px, #000 ${edgeFeather}px, #000 100%)`;

  return (
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
        opacity: progress,
        transform: `translateY(${translateY}px) scale(.705)`,
        transformOrigin: 'center center',
        translate: '-220.6px 98.8px',
        borderRadius: '34px 34px 0 0',
        WebkitMaskImage: `${horizontalEdgeMask}, ${topEdgeMask}`,
        maskImage: `${horizontalEdgeMask}, ${topEdgeMask}`,
        WebkitMaskComposite: 'destination-in',
        maskComposite: 'intersect',
        WebkitMaskRepeat: 'no-repeat',
        maskRepeat: 'no-repeat',
      }}
    />
  );
};

export const SceneOne: React.FC = () => (
  <AbsoluteFill>
    <Backdrop accent={MARKER_COLOR} />
    <Sequence from={58} durationInFrames={63}>
      <GlassTrack />
    </Sequence>
    <Sequence from={35} durationInFrames={86}>
      <CalendarTrack />
    </Sequence>
    <Sequence from={68} durationInFrames={53}>
      <TitleTrack />
    </Sequence>
    <Sequence from={0} durationInFrames={111}>
      <MarkerTrack />
    </Sequence>
  </AbsoluteFill>
);
