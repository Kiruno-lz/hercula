import {Composition, registerRoot} from 'remotion';
import {PROMO_DURATION, Promo} from './Promo';

export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="HerCuLaPromo"
      component={Promo}
      durationInFrames={PROMO_DURATION}
      fps={30}
      width={1920}
      height={1080}
      defaultProps={{bgm: true}}
    />
  );
};

registerRoot(RemotionRoot);
