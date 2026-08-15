const IMPORT_DIALOG_HEIGHT: number = 420;
const IMPORT_TEXT_AREA_HEIGHT: number = 148;
const IMPORT_NOTICE_HEIGHT: number = 40;
const ACCENT_COLOR: string = '#A95E70';
const TEXT_COLOR: string = '#594B50';
const MUTED_TEXT: string = '#8E7B82';

@Component
export struct TextImportComponent {
  @Prop textImportInput: string = '';
  @Prop textImportNotice: string = '';
  onInputChange: (value: string) => void = (_value: string): void => {};
  onLoadJson: () => void = (): void => {};
  onCancel: () => void = (): void => {};
  onContinue: () => void = (): void => {};

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#38F1DDE1')
        .backgroundBlurStyle(BlurStyle.Thin, { scale: 0.1 })
        .onClick((): void => {})

      Column({ space: 12 }) {
        Column({ space: 4 }) {
          Text('导入日期')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_COLOR)
          Text('每行输入一个经期开始日期')
            .fontSize(14)
            .fontColor(ACCENT_COLOR)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        TextArea({
          placeholder: '例如：2026年8月10日、8月10日或26-8-10',
          text: this.textImportInput
        })
          .fontSize(16)
          .fontColor(TEXT_COLOR)
          .placeholderColor(MUTED_TEXT)
          .textAlign(TextAlign.Start)
          .backgroundColor('#35FFF9FA')
          .borderRadius(20)
          .padding({ left: 18, right: 18, top: 16, bottom: 16 })
          .width('100%')
          .height(IMPORT_TEXT_AREA_HEIGHT)
          .onChange((value: string): void => {
            this.onInputChange(value);
          })

        Text('支持 -、/、. 和中文年月日分隔；年份可省略或省略前面的 20')
          .fontSize(13)
          .fontColor(TEXT_COLOR)
          .width('100%')

        if (this.textImportNotice.length > 0) {
          Text(this.textImportNotice)
            .fontSize(13)
            .fontColor(ACCENT_COLOR)
            .width('100%')
            .maxLines(2)
        }

        Button('从 JSON 文件加载')
          .fontSize(15)
          .fontColor(ACCENT_COLOR)
          .backgroundColor('#EAD1D6')
          .borderRadius(22)
          .height(44)
          .width('100%')
          .padding(0)
          .onClick((): void => {
            this.onLoadJson();
          })

        Row({ space: 14 }) {
          Button('取消')
            .fontSize(16)
            .fontColor(ACCENT_COLOR)
            .backgroundColor('#22FFFFFF')
            .border({ width: 1, color: '#55FFFFFF' })
            .borderRadius(22)
            .height(44)
            .layoutWeight(1)
            .padding(0)
            .onClick((): void => {
              this.onCancel();
            })
          Button('继续')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFF9FA')
            .backgroundColor('#D78193')
            .borderRadius(22)
            .height(44)
            .layoutWeight(1)
            .padding(0)
            .onClick((): void => {
              this.onContinue();
            })
        }
        .width('100%')
      }
      .width('82%')
      .height(this.textImportNotice.length > 0
        ? IMPORT_DIALOG_HEIGHT + IMPORT_NOTICE_HEIGHT
        : IMPORT_DIALOG_HEIGHT)
      .constraintSize({ maxWidth: 420 })
      .padding({ left: 24, right: 24, top: 24, bottom: 20 })
      .backgroundColor('#E9FFF9FA')
      .backgroundBlurStyle(BlurStyle.Thin, { scale: 0.1 })
      .backgroundEffect({ radius: 28, saturation: 1.04, brightness: 1.03 })
      .border({ width: 1, color: '#B8FFFFFF' })
      .borderRadius(24)
      .shadow({ radius: 28, color: '#459B7280', offsetX: 0, offsetY: 12 })
      .transition(TransitionEffect.OPACITY
        .combine(TransitionEffect.scale({ x: 0.94, y: 0.94 }))
        .animation({ duration: 220, curve: Curve.EaseOut }))
    }
    .width('100%')
    .height('100%')
    .zIndex(20)
  }
}
