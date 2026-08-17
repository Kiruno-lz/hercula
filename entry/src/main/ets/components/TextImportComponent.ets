import { DEFAULT_THEME_ID, resolveTheme, ThemePalette } from '../domain/Theme';

const IMPORT_DIALOG_HEIGHT: number = 420;
const IMPORT_TEXT_AREA_HEIGHT: number = 148;
const IMPORT_NOTICE_HEIGHT: number = 40;
const DEFAULT_THEME: ThemePalette = resolveTheme(DEFAULT_THEME_ID);

@Component
export struct TextImportComponent {
  @Prop textImportInput: string = '';
  @Prop textImportNotice: string = '';
  @Prop theme: ThemePalette = DEFAULT_THEME;
  onInputChange: (value: string) => void = (_value: string): void => {};
  onLoadJson: () => void = (): void => {};
  onCancel: () => void = (): void => {};
  onContinue: () => void = (): void => {};

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.theme.scrim)
        .backgroundBlurStyle(BlurStyle.Thin, { scale: 0.1 })
        .onClick((): void => {})

      Column({ space: 12 }) {
        Column({ space: 4 }) {
          Text('导入日期')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.theme.text)
          Text('每行输入一个经期开始日期')
            .fontSize(14)
            .fontColor(this.theme.accent)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        TextArea({
          placeholder: '例如：2026年8月10日、8月10日或26-8-10',
          text: this.textImportInput
        })
          .fontSize(16)
          .fontColor(this.theme.text)
          .placeholderColor(this.theme.mutedText)
          .textAlign(TextAlign.Start)
          .backgroundColor(this.theme.glassSurface)
          .borderRadius(20)
          .padding({ left: 18, right: 18, top: 16, bottom: 16 })
          .width('100%')
          .height(IMPORT_TEXT_AREA_HEIGHT)
          .onChange((value: string): void => {
            this.onInputChange(value);
          })

        Text('支持 -、/、. 和中文年月日分隔；年份可省略或省略前面的 20')
          .fontSize(13)
          .fontColor(this.theme.text)
          .width('100%')

        if (this.textImportNotice.length > 0) {
          Text(this.textImportNotice)
            .fontSize(13)
            .fontColor(this.theme.accent)
            .width('100%')
            .maxLines(2)
        }

        Button('从 JSON 文件加载')
          .fontSize(15)
          .fontColor(this.theme.accent)
          .backgroundColor(this.theme.secondaryButton)
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
            .fontColor(this.theme.accent)
            .backgroundColor(this.theme.glassSurface)
            .border({ width: 1, color: this.theme.glassBorder })
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
            .fontColor(this.theme.periodText)
            .backgroundColor(this.theme.primaryButton)
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
      .backgroundColor(this.theme.glassSurface)
      .backgroundBlurStyle(BlurStyle.Thin, { scale: 0.1 })
      .backgroundEffect({ radius: 28, saturation: 1.04, brightness: 1.03 })
      .border({ width: 1, color: this.theme.glassBorder })
      .borderRadius(24)
      .shadow({ radius: 28, color: this.theme.glassShadow, offsetX: 0, offsetY: 12 })
      .transition(TransitionEffect.OPACITY
        .combine(TransitionEffect.scale({ x: 0.94, y: 0.94 }))
        .animation({ duration: 220, curve: Curve.EaseOut }))
    }
    .width('100%')
    .height('100%')
    .zIndex(20)
  }
}
