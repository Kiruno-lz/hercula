const TEXT_COLOR: string = '#594B50';
const ACCENT_COLOR: string = '#A95E70';
const MUTED_TEXT: string = '#8E7B82';

@Component
export struct WelcomeComponent {
  onStart: () => void = (): void => {};
  onImport: () => void = (): void => {};

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#38F1DDE1')
        .backgroundBlurStyle(BlurStyle.Thin, { scale: 0.1 })
        .onClick((): void => {})

      Column({ space: 16 }) {
        Text('欢迎使用月迹')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_COLOR)
          .textAlign(TextAlign.Center)
          .width('100%')

        Column({ space: 4 }) {
          Text('点击日期，记录开始日')
            .fontSize(14)
            .fontColor(ACCENT_COLOR)
            .textAlign(TextAlign.Center)
            .width('100%')
          Text('再次点击，可取消记录')
            .fontSize(14)
            .fontColor(ACCENT_COLOR)
            .textAlign(TextAlign.Center)
            .width('100%')
        }

        Blank()
          .height(20)

        Row({ space: 8 }) {
          Circle()
            .width(8)
            .height(8)
            .fill('#B9CDE5')
          Text('记录仅保存在本地')
            .fontSize(13)
            .fontColor(MUTED_TEXT)
        }

        Blank()
          .layoutWeight(1)

        Row({ space: 16 }) {
          Button('开始记录')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFF9FA')
            .backgroundColor('#D78193')
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
            .fontColor(ACCENT_COLOR)
            .backgroundColor('#E9FFF9FA')
            .border({ width: 1, color: '#55FFFFFF' })
            .borderRadius(26)
            .height(52)
            .layoutWeight(1)
            .padding(0)
            .shadow({ radius: 12, color: '#208B5B64', offsetX: 0, offsetY: 4 })
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
      .backgroundColor('#E9FFF9FA')
      .backgroundBlurStyle(BlurStyle.Thin, { scale: 0.1 })
      .backgroundEffect({ radius: 28, saturation: 1.04, brightness: 1.03 })
      .border({ width: 1, color: '#B8FFFFFF' })
      .borderRadius(24)
      .shadow({ radius: 28, color: '#459B7280', offsetX: 0, offsetY: 12 })
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
