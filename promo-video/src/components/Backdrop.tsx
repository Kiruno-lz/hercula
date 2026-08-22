import React from 'react';
import {AbsoluteFill} from 'remotion';

export const PROMO_BACKGROUND =
  'radial-gradient(ellipse 58% 72% at 12% 72%, #F1C9D3AA 0%, transparent 72%), radial-gradient(ellipse 60% 72% at 91% 72%, #DCEAE4CC 0%, transparent 72%), linear-gradient(110deg, #FDF8F1 0%, #F6E6EA 48%, #EEF5F0 100%)';

const NOISE_TEXTURE =
  'url("data:image/svg+xml,%3Csvg xmlns=\'http://www.w3.org/2000/svg\' width=\'160\' height=\'160\' viewBox=\'0 0 160 160\'%3E%3Cfilter id=\'n\'%3E%3CfeTurbulence type=\'fractalNoise\' baseFrequency=\'.9\' numOctaves=\'3\' stitchTiles=\'stitch\'/%3E%3C/filter%3E%3Crect width=\'100%\' height=\'100%\' filter=\'url(%23n)\' opacity=\'.035\'/%3E%3C/svg%3E")';

export const Backdrop: React.FC<{accent?: string}> = ({accent = '#D77F91'}) => (
  <AbsoluteFill style={{background: PROMO_BACKGROUND}}>
    <AbsoluteFill
      style={{
        background: `radial-gradient(circle at 50% 50%, ${accent} 0%, transparent 62%)`,
        opacity: 0.08,
        mixBlendMode: 'multiply',
      }}
    />
    <AbsoluteFill
      style={{
        pointerEvents: 'none',
        opacity: 0.16,
        mixBlendMode: 'multiply',
        backgroundImage: NOISE_TEXTURE,
      }}
    />
  </AbsoluteFill>
);
