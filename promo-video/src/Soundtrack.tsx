import React from 'react';
import {Audio, Sequence, interpolate, staticFile} from 'remotion';
import {SCENE_ONE_DURATION} from './scenes/SceneOne';
import {SCENE_TWO_DURATION} from './scenes/SceneTwo';
import {SCENE_THREE_DURATION} from './scenes/SceneThree';
import {SCENE_FOUR_DURATION} from './scenes/SceneFour';
import {SCENE_FIVE_DURATION} from './scenes/SceneFive';

const TOTAL_DURATION =
  SCENE_ONE_DURATION +
  SCENE_TWO_DURATION +
  SCENE_THREE_DURATION +
  SCENE_FOUR_DURATION +
  SCENE_FIVE_DURATION;

const CAT_WALK_START_FRAME = 2544;

const SCENE_STARTS = {
  one: 0,
  two: SCENE_ONE_DURATION,
  three: SCENE_ONE_DURATION + SCENE_TWO_DURATION,
  four: SCENE_ONE_DURATION + SCENE_TWO_DURATION + SCENE_THREE_DURATION,
  five:
    SCENE_ONE_DURATION + SCENE_TWO_DURATION + SCENE_THREE_DURATION + SCENE_FOUR_DURATION,
};

type SoundCue = {
  id: string;
  from: number;
  durationInFrames: number;
  src: string;
  volume: number;
};

const SFX: SoundCue[] = [
  // {
  //   id: 'single-swiper',
  //   from: SCENE_STARTS.three + 16,
  //   durationInFrames: 53,
  //   src: staticFile('audio/whoosh-fast.mp3'),
  //   volume: 0.12,
  // },
  {
    id: 'morph-to-dual',
    from: SCENE_STARTS.four + 14,
    durationInFrames: 35,
    src: staticFile('audio/glass-plate-slide.mp3'),
    volume: 0.1,
  },
  {
    id: 'morph-to-scroll',
    from: SCENE_STARTS.four + 72,
    durationInFrames: 35,
    src: staticFile('audio/glass-plate-slide.mp3'),
    volume: 0.08,
  },
  {
    id: 'morph-to-compact',
    from: SCENE_STARTS.four + 128,
    durationInFrames: 35,
    src: staticFile('audio/glass-plate-slide.mp3'),
    volume: 0.06,
  },
];

export const Soundtrack: React.FC<{bgm: boolean}> = ({bgm}) => (
  <>
    {bgm ? (
      <Audio
        src={staticFile('audio/cat-walk.mp3')}
        startFrom={CAT_WALK_START_FRAME}
        volume={(frame) =>
          interpolate(
            frame,
            [0, 30, 580, 600],
            [0, 0.25, 0.25, 0],
            {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'},
          )
        }
      />
    ) : null}
    {SFX.map((cue) => (
      <Sequence key={cue.id} from={cue.from} durationInFrames={cue.durationInFrames}>
        <Audio src={cue.src} volume={cue.volume} />
      </Sequence>
    ))}
  </>
);
