import React from 'react';
import {AbsoluteFill, Img, interpolateColors, staticFile, useCurrentFrame} from 'remotion';
import {Backdrop} from '../components/Backdrop';
import {GlassFrame} from '../components/GlassFrame';
import {segment} from '../motion';

export const SCENE_TWO_DURATION = 110;

const CALENDAR_IMAGE = staticFile('ui/first-stage-single-calendar.png');
const TITLE_IMAGE = staticFile('ui/title-lockup.png');
const EDGE_FEATHER = 3;
const HORIZONTAL_EDGE_MASK = `linear-gradient(90deg, transparent 0px, #000 ${EDGE_FEATHER}px, #000 calc(100% - ${EDGE_FEATHER}px), transparent 100%)`;
const CALENDAR_BOTTOM_EDGE_MASK = `linear-gradient(to top, transparent 0px, #000 ${EDGE_FEATHER}px, #000 100%)`;
const TITLE_TOP_EDGE_MASK = `linear-gradient(to bottom, transparent 0px, #000 ${EDGE_FEATHER}px, #000 100%)`;

type ThemeLayer = {
  id: 'rose' | 'sage' | 'indigo' | 'coral';
  filter: string;
  color: string;
};

const THEMES: Record<ThemeLayer['id'], ThemeLayer> = {
  rose: {id: 'rose', filter: 'none', color: '#D77F91'},
  sage: {
    id: 'sage',
    filter: 'hue-rotate(151deg) saturate(1.02) brightness(.965) contrast(1.04)',
    color: '#73A28C',
  },
  indigo: {
    id: 'indigo',
    filter: 'hue-rotate(262deg) saturate(1.18) brightness(.965) contrast(1.04)',
    color: '#8B78D7',
  },
  coral: {
    id: 'coral',
    filter: 'hue-rotate(18deg) saturate(1.72) brightness(.94) contrast(1.05)',
    color: '#ec4e27',
  },
};

const THEME_TRANSITION = 6;

const layerOpacity = (frame: number, theme: ThemeLayer['id']) => {
  if (theme === 'rose') {
    return Math.max(
      1 - segment(frame, 0, THEME_TRANSITION),
      segment(frame, 82, 82 + THEME_TRANSITION),
    );
  }
  if (theme === 'indigo') {
    return Math.min(
      segment(frame, 0, THEME_TRANSITION),
      1 - segment(frame, 28, 28 + THEME_TRANSITION),
    );
  }
  if (theme === 'coral') {
    return Math.min(
      segment(frame, 28, 28 + THEME_TRANSITION),
      1 - segment(frame, 56, 56 + THEME_TRANSITION),
    );
  }
  if (theme === 'sage') {
    return Math.min(
      segment(frame, 56, 56 + THEME_TRANSITION),
      1 - segment(frame, 82, 82 + THEME_TRANSITION),
    );
  }
  return 0;
};

const ThemePanel: React.FC<{theme: ThemeLayer; opacity: number}> = ({theme, opacity}) => (
  <AbsoluteFill style={{opacity, filter: theme.filter}}>
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
  </AbsoluteFill>
);

export const SceneTwo: React.FC = () => {
  const frame = useCurrentFrame();
  const accent = interpolateColors(
    frame,
    [
      0,
      THEME_TRANSITION,
      28,
      28 + THEME_TRANSITION,
      56,
      56 + THEME_TRANSITION,
      82,
      82 + THEME_TRANSITION,
      SCENE_TWO_DURATION,
    ],
    [
      THEMES.rose.color,
      THEMES.indigo.color,
      THEMES.indigo.color,
      THEMES.coral.color,
      THEMES.coral.color,
      THEMES.sage.color,
      THEMES.sage.color,
      THEMES.rose.color,
      THEMES.rose.color,
    ],
  );

  return (
    <AbsoluteFill>
      <Backdrop accent={accent} />
      <AbsoluteFill>
        <GlassFrame left={708} top={153} width={510} height={733} radius={34} />
      </AbsoluteFill>
      {(Object.keys(THEMES) as ThemeLayer['id'][]).map((themeId) => (
        <ThemePanel
          key={themeId}
          theme={THEMES[themeId]}
          opacity={layerOpacity(frame, themeId)}
        />
      ))}
    </AbsoluteFill>
  );
};
