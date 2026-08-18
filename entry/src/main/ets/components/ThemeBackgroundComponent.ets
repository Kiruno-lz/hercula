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
        .width('128%')
        .height('128%')
        .fill(this.theme.backgroundOrbPrimary)
        .scale({
          x: this.orbScale(0),
          y: this.orbScale(0)
        })
        .translate({
          x: this.orbOffsetX(0),
          y: this.orbOffsetY(0)
        })
        .animation({ duration: MOTION_ANIMATION_MS, curve: Curve.EaseInOut })

      Circle()
        .width('88%')
        .height('88%')
        .fill(this.theme.backgroundOrbSecondary)
        .scale({
          x: this.orbScale(1),
          y: this.orbScale(1)
        })
        .translate({
          x: this.orbOffsetX(1),
          y: this.orbOffsetY(1)
        })
        .animation({ duration: MOTION_ANIMATION_MS + 1200, curve: Curve.EaseInOut })

      Circle()
        .width('0%')
        .height('0%')
        .fill(this.theme.backgroundOrbTertiary)
        .scale({
          x: this.orbScale(2),
          y: this.orbScale(2)
        })
        .translate({
          x: this.orbOffsetX(2),
          y: this.orbOffsetY(2)
        })
        .animation({ duration: MOTION_ANIMATION_MS + 700, curve: Curve.EaseInOut })

      Column()
        .width('100%')
        .height('130%')
        .backgroundColor(this.theme.backgroundBlurOverlay)
        .backgroundBlurStyle(BlurStyle.Thick, { scale: 0.8 })
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
      [0.16, 0.24, 0.18, 0.10],
      [-0.16, -0.22, -0.14, -0.08],
      [0.00, 0.00, 0.00, 0.00]
    ];
    return this.viewportWidth * positions[orbIndex][this.motionStep];
  }

  private orbOffsetY(orbIndex: number): number {
    const positions: Array<Array<number>> = [
      [0.12, 0.20, 0.16, 0.08],
      [-0.12, -0.18, -0.10, -0.06],
      [0.00, 0.00, 0.00, 0.00]
    ];
    return this.viewportHeight * positions[orbIndex][this.motionStep];
  }

  private orbScale(orbIndex: number): number {
    const scales: Array<Array<number>> = [
      [1.00, 1.08, 0.96, 1.04],
      [1.00, 0.94, 1.06, 0.98],
      [1.00, 1.03, 1.00, 0.97]
    ];
    return scales[orbIndex][this.motionStep];
  }
}
