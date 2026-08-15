const TEXT_COLOR: string = '#594B50';
const ACCENT_COLOR: string = '#A95E70';
const MUTED_TEXT: string = '#8E7B82';
const ABOUT_DIALOG_HEIGHT: number = 390;

@Component
export struct AboutComponent {
  @Prop repositoryUrl: string = 'https://github.com/Kiruno-lz/hercula';
  onClose: () => void = (): void => {};

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#38F1DDE1')
        .backgroundBlurStyle(BlurStyle.Thin, { scale: 0.1 })
        .onClick((): void => {
          this.onClose();
        })

      Column({ space: 12 }) {
        Blank()
          .height(40)

        Text('关于月迹')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_COLOR)
          .textAlign(TextAlign.Center)
          .width('100%')

        Text('hercula · 本地隐私记录')
          .fontSize(15)
          .fontColor(ACCENT_COLOR)
          .textAlign(TextAlign.Center)
          .width('100%')

        Blank()
          .height(20)

        Text('☕')
          .fontSize(52)
          .opacity(0.72)
          .textAlign(TextAlign.Center)
          .width('100%')

        Blank()
          .height(5)

        Text('喜欢这个项目的话，点个 Star')
          .fontSize(14)
          .fontColor(MUTED_TEXT)
          .textAlign(TextAlign.Center)
          .width('100%')

        Text(this.repositoryUrl)
          .fontSize(12)
          .fontColor(ACCENT_COLOR)
          .textAlign(TextAlign.Center)
          .width('100%')
          .maxLines(2)
      }
      .width('82%')
      .height(ABOUT_DIALOG_HEIGHT)
      .constraintSize({ maxWidth: 420 })
      .padding({ left: 28, right: 28, top: 28, bottom: 24 })
      .backgroundColor('#E9FFF9FA')
      .backgroundBlurStyle(BlurStyle.Thin, { scale: 0.1 })
      .backgroundEffect({ radius: 28, saturation: 1.04, brightness: 1.03 })
      .border({ width: 1, color: '#B8FFFFFF' })
      .borderRadius(24)
      .shadow({ radius: 28, color: '#459B7280', offsetX: 0, offsetY: 12 })
      .onClick((): void => {
        this.onClose();
      })
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
