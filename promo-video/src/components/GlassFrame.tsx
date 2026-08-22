import React from 'react';

export type GlassFrameGeometry = {
  left: number;
  top: number;
  width: number;
  height: number;
  radius: number;
};

type GlassFrameProps = GlassFrameGeometry & {
  opacity?: number;
  scale?: number;
};

export const GlassFrame: React.FC<GlassFrameProps> = ({
  left,
  top,
  width,
  height,
  radius,
  opacity = 1,
  scale = 1,
}) => (
  <div
    style={{
      position: 'absolute',
      left,
      top,
      width,
      height,
      opacity,
      transform: `scale(${scale})`,
      transformOrigin: 'center center',
      borderRadius: radius,
      background: 'linear-gradient(145deg, rgba(255,255,255,.34), rgba(255,255,255,.08))',
      border: '1.5px solid rgba(255,255,255,.86)',
      boxShadow:
        'inset 0 1px 0 rgba(255,255,255,.94), inset 0 -1px 0 rgba(255,255,255,.18), 0 28px 60px rgba(102,74,82,.16), 0 8px 20px rgba(102,74,82,.10)',
      backdropFilter: 'blur(18px) saturate(1.08)',
      WebkitBackdropFilter: 'blur(18px) saturate(1.08)',
    }}
  />
);
