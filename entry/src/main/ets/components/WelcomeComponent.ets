import { DEFAULT_THEME_ID, resolveTheme, ThemePalette } from '../domain/Theme';

const DEFAULT_THEME: ThemePalette = resolveTheme(DEFAULT_THEME_ID);

@Component
export struct WelcomeComponent {
  @Prop theme: ThemePalette = DEFAULT_THEME;
  onStart: () => void = (): void => {};
  onImport: () => void = (): void => {};

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.theme.scrim)
        .backgroundBlurStyle(BlurStyle.Thin, { scale: 0.1 })
        .onClick((): void => {})

      Column({ space: 16 }) {
        Text('欢迎使用月迹')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.text)
          .textAlign(TextAlign.Center)
          .width('100%')

        Column({ space: 4 }) {
          Text('点击日期，记录开始日')
            .fontSize(14)
            .fontColor(this.theme.accent)
            .textAlign(TextAlign.Center)
            .width('100%')
          Text('再次点击，可取消记录')
            .fontSize(14)
            .fontColor(this.theme.accent)
            .textAlign(TextAlign.Center)
            .width('100%')
        }

        Blank()
          .height(20)

        Row({ space: 8 }) {
          Circle()
            .width(8)
            .height(8)
            .fill(this.theme.welcomeBullet)
          Text('记录仅保存在本地')
            .fontSize(13)
            .fontColor(this.theme.mutedText)
        }

        Blank()
          .layoutWeight(1)

        Row({ space: 16 }) {
          Button('开始记录')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.theme.periodText)
            .backgroundColor(this.theme.primaryButton)
            .borderRadius(26)
            .height(52)
            .layoutWeight(1)
            .padding(0)
            .onClick((): void => {
              this.onStart();
            })
          Button('导入数据')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.theme.accent)
            .backgroundColor(this.theme.glassSurface)
            .border({ width: 1, color: this.theme.glassBorder })
            .borderRadius(26)
            .height(52)
            .layoutWeight(1)
            .padding(0)
            .shadow({ radius: 12, color: this.theme.glassShadow, offsetX: 0, offsetY: 4 })
            .onClick((): void => {
              this.onImport();
            })
        }
        .width('100%')
      }
      .width('82%')
      .height(320)
      .constraintSize({ maxWidth: 420 })
      .padding({ left: 28, right: 28, top: 46, bottom: 46 })
      .backgroundColor(this.theme.glassSurface)
      .backgroundBlurStyle(BlurStyle.Thin, { scale: 0.1 })
      .backgroundEffect({ radius: 28, saturation: 1.04, brightness: 1.03 })
      .border({ width: 1, color: this.theme.glassBorder })
      .borderRadius(24)
      .shadow({ radius: 28, color: this.theme.glassShadow, offsetX: 0, offsetY: 12 })
      .transition(TransitionEffect.OPACITY
        .combine(TransitionEffect.scale({ x: 0.94, y: 0.94 }))
        .combine(TransitionEffect.translate({ y: 18 }))
        .animation({ duration: 220, curve: Curve.EaseOut }))
    }
    .width('100%')
    .height('100%')
    .zIndex(30)
  }
}
