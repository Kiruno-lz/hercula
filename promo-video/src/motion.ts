import {Easing, interpolate} from 'remotion';

export const clamp01 = (value: number) => Math.max(0, Math.min(1, value));

export const segment = (
  frame: number,
  start: number,
  end: number,
  easing: (value: number) => number = Easing.inOut(Easing.cubic),
) => {
  if (end <= start) return frame >= end ? 1 : 0;
  return interpolate(frame, [start, end], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing,
  });
};

export const fade = (frame: number, start: number, end: number) =>
  segment(frame, start, end, Easing.out(Easing.cubic));

export const pulse = (frame: number, start: number, end: number, cycles = 1) => {
  const p = segment(frame, start, end, Easing.linear);
  return Math.sin(p * Math.PI * 2 * cycles);
};
