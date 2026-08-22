import React from 'react';
import {AbsoluteFill, Sequence} from 'remotion';
import {SceneOne, SCENE_ONE_DURATION} from './scenes/SceneOne';
import {SceneTwo, SCENE_TWO_DURATION} from './scenes/SceneTwo';
import {SceneThree, SCENE_THREE_DURATION} from './scenes/SceneThree';
import {SceneFour, SCENE_FOUR_DURATION} from './scenes/SceneFour';
import {SceneFive, SCENE_FIVE_DURATION} from './scenes/SceneFive';
import {Soundtrack} from './Soundtrack';

export type PromoProps = {
  bgm?: boolean;
};

export const PROMO_DURATION =
  SCENE_ONE_DURATION +
  SCENE_TWO_DURATION +
  SCENE_THREE_DURATION +
  SCENE_FOUR_DURATION +
  SCENE_FIVE_DURATION;

export const Promo: React.FC<PromoProps> = ({bgm = true}) => (
  <AbsoluteFill style={{background: '#FDF8F1'}}>
    <Sequence from={0} durationInFrames={SCENE_ONE_DURATION} premountFor={30}>
      <SceneOne />
    </Sequence>
    <Sequence
      from={SCENE_ONE_DURATION}
      durationInFrames={SCENE_TWO_DURATION}
      premountFor={30}
    >
      <SceneTwo />
    </Sequence>
    <Sequence
      from={SCENE_ONE_DURATION + SCENE_TWO_DURATION}
      durationInFrames={SCENE_THREE_DURATION}
      premountFor={30}
    >
      <SceneThree />
    </Sequence>
    <Sequence
      from={SCENE_ONE_DURATION + SCENE_TWO_DURATION + SCENE_THREE_DURATION}
      durationInFrames={SCENE_FOUR_DURATION}
      premountFor={30}
    >
      <SceneFour />
    </Sequence>
    <Sequence
      from={SCENE_ONE_DURATION + SCENE_TWO_DURATION + SCENE_THREE_DURATION + SCENE_FOUR_DURATION}
      durationInFrames={SCENE_FIVE_DURATION}
      premountFor={30}
    >
      <SceneFive />
    </Sequence>
    <Soundtrack bgm={bgm} />
  </AbsoluteFill>
);
