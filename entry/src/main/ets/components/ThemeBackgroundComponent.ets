import { DEFAULT_THEME_ID, resolveTheme, ThemePalette } from '../domain/Theme';

const DEFAULT_THEME: ThemePalette = resolveTheme(DEFAULT_THEME_ID);
const MOTION_INTERVAL_MS: number = 8200;
const MOTION_ANIMATION_MS: number = 9000;

@Component
export struct ThemeBackgroundComponent {
  @Prop theme: ThemePalette = DEFAULT_THEME;

  @State private motionStep: number = 0;
  @State private viewportWidth: number = 1;
  @State private viewportHeight: number = 1;
  private motionTimer: number = -1;

  aboutToAppear(): void {
    this.motionTimer = setInterval((): void => {
      this.motionStep = (this.motionStep + 1) % 4;
    }, MOTION_INTERVAL_MS);
  }

  aboutToDisappear(): void {
    if (this.motionTimer >= 0) {
      clearInterval(this.motionTimer);
      this.motionTimer = -1;
    }
  }

  build() {
    Stack() {
      Circle()
        .width('78%')
        .height('78%')
        .fill(this.theme.backgroundOrbPrimary)
        .translate({
          x: this.orbOffsetX(0),
          y: this.orbOffsetY(0)
        })
        .animation({ duration: MOTION_ANIMATION_MS, curve: Curve.EaseInOut })

      Circle()
        .width('58%')
        .height('58%')
        .fill(this.theme.backgroundOrbSecondary)
        .translate({
          x: this.orbOffsetX(1),
          y: this.orbOffsetY(1)
        })
        .animation({ duration: MOTION_ANIMATION_MS + 1200, curve: Curve.EaseInOut })

      Circle()
        .width('42%')
        .height('42%')
        .fill(this.theme.backgroundOrbTertiary)
        .translate({
          x: this.orbOffsetX(2),
          y: this.orbOffsetY(2)
        })
        .animation({ duration: MOTION_ANIMATION_MS + 700, curve: Curve.EaseInOut })

      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.theme.backgroundBlurOverlay)
        .backgroundBlurStyle(BlurStyle.Thin, { scale: 0.8 })
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Transparent)
    .onAreaChange((_oldValue: Area, newValue: Area): void => {
      this.viewportWidth = Math.max(1, newValue.width as number);
      this.viewportHeight = Math.max(1, newValue.height as number);
    })
  }

  private orbOffsetX(orbIndex: number): number {
    const positions: Array<Array<number>> = [
      [-0.12, 0.08, 0.02, -0.10],
      [0.10, -0.08, 0.12, 0.00],
      [-0.04, 0.10, -0.10, 0.06]
    ];
    return this.viewportWidth * positions[orbIndex][this.motionStep];
  }

  private orbOffsetY(orbIndex: number): number {
    const positions: Array<Array<number>> = [
      [0.06, -0.04, 0.08, -0.03],
      [-0.05, 0.10, -0.02, 0.08],
      [0.12, -0.08, 0.04, -0.06]
    ];
    return this.viewportHeight * positions[orbIndex][this.motionStep];
  }
}
