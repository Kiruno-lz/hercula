import { ImportValidationResult } from '../domain/ImportValidator';
import { DEFAULT_THEME_ID, resolveTheme, ThemePalette } from '../domain/Theme';

const IMPORT_DIALOG_HEIGHT: number = 420;
const DEFAULT_THEME: ThemePalette = resolveTheme(DEFAULT_THEME_ID);

@Component
export struct ImportConfirmationComponent {
  @Prop importValidation: ImportValidationResult = {
    candidateDates: [],
    validDates: [],
    futureDates: [],
    duplicateDates: [],
    existingDates: [],
    invalidTokens: []
  };
  @Prop theme: ThemePalette = DEFAULT_THEME;
  onBack: () => void = (): void => {};
  onConfirm: () => void = (): void => {};

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
          Text('确认导入')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.theme.text)
          Text(this.importSummaryText())
            .fontSize(14)
            .fontColor(this.theme.accent)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        Scroll() {
          Column({ space: 4 }) {
            ForEach(this.importValidation.candidateDates, (date: string) => {
              this.buildImportPreviewRow(date, this.importStatus(date));
            }, (date: string): string => `candidate-${date}`)
            ForEach(this.importValidation.invalidTokens, (token: string) => {
              this.buildImportPreviewRow(token, '无效内容');
            }, (token: string): string => `invalid-${token}`)
          }
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
        .align(Alignment.TopStart)
        .scrollBar(BarState.Auto)

        if (this.importValidation.invalidTokens.length > 0 || this.importValidation.futureDates.length > 0) {
          Text('无效日期和未来日期不会写入记录')
            .fontSize(13)
            .fontColor(this.theme.mutedText)
            .width('100%')
            .maxLines(2)
        }

        Row({ space: 14 }) {
          Button('返回')
            .fontSize(16)
            .fontColor(this.theme.accent)
            .backgroundColor(this.theme.glassSurface)
            .border({ width: 1, color: this.theme.glassBorder })
            .borderRadius(22)
            .height(44)
            .layoutWeight(1)
            .padding(0)
            .onClick((): void => {
              this.onBack();
            })
          Button(`导入 ${this.importValidation.validDates.length} 条`)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.theme.periodText)
            .backgroundColor(this.theme.primaryButton)
            .borderRadius(22)
            .height(44)
            .layoutWeight(1)
            .padding(0)
            .enabled(this.importValidation.validDates.length > 0)
            .onClick((): void => {
              this.onConfirm();
            })
        }
        .width('100%')
      }
      .width('82%')
      .height(IMPORT_DIALOG_HEIGHT)
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
    .zIndex(21)
  }

  @Builder
  private buildImportPreviewRow(value: string, status: string) {
    Row() {
      Text(value)
        .fontSize(15)
        .fontColor(status === '无效内容' ? this.theme.accent : this.theme.text)
        .layoutWeight(1)
        .maxLines(1)
      Text(status)
        .fontSize(13)
        .fontColor(status === '新增' ? this.theme.accent : this.theme.mutedText)
    }
    .padding({ left: 14, right: 14 })
    .height(38)
    .width('100%')
    .backgroundColor(status === '新增' ? this.theme.glassSurface : this.theme.secondaryButton)
    .borderRadius(14)
  }

  private importSummaryText(): string {
    const recognized: number = this.importValidation.candidateDates.length +
      this.importValidation.invalidTokens.length;
    const duplicateCount: number = this.importValidation.duplicateDates.length +
      this.importValidation.existingDates.length;
    const failedCount: number = this.importValidation.futureDates.length +
      this.importValidation.invalidTokens.length;
    return `识别 ${recognized} 条 · 可导入 ${this.importValidation.validDates.length} 条 · 重复 ${duplicateCount} 条 · 失败 ${failedCount} 条`;
  }

  private importStatus(date: string): string {
    if (this.importValidation.futureDates.includes(date)) {
      return '未来日期';
    }
    if (this.importValidation.existingDates.includes(date)) {
      return '已存在';
    }
    if (this.importValidation.duplicateDates.includes(date)) {
      return '重复';
    }
    return '新增';
  }
}
