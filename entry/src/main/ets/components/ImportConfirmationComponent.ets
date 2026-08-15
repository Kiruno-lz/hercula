import { ImportValidationResult } from '../domain/ImportValidator';

const IMPORT_DIALOG_HEIGHT: number = 420;
const ACCENT_COLOR: string = '#A95E70';
const TEXT_COLOR: string = '#594B50';
const MUTED_TEXT: string = '#8E7B82';

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
  onBack: () => void = (): void => {};
  onConfirm: () => void = (): void => {};

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
          Text('确认导入')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_COLOR)
          Text(this.importSummaryText())
            .fontSize(14)
            .fontColor(ACCENT_COLOR)
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
            .fontColor(MUTED_TEXT)
            .width('100%')
            .maxLines(2)
        }

        Row({ space: 14 }) {
          Button('返回')
            .fontSize(16)
            .fontColor(ACCENT_COLOR)
            .backgroundColor('#22FFFFFF')
            .border({ width: 1, color: '#55FFFFFF' })
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
            .fontColor('#FFF9FA')
            .backgroundColor('#D78193')
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
    .zIndex(21)
  }

  @Builder
  private buildImportPreviewRow(value: string, status: string) {
    Row() {
      Text(value)
        .fontSize(15)
        .fontColor(status === '无效内容' ? ACCENT_COLOR : TEXT_COLOR)
        .layoutWeight(1)
        .maxLines(1)
      Text(status)
        .fontSize(13)
        .fontColor(status === '新增' ? ACCENT_COLOR : MUTED_TEXT)
    }
    .padding({ left: 14, right: 14 })
    .height(38)
    .width('100%')
    .backgroundColor(status === '新增' ? '#18FFF9FA' : '#12EAD1D6')
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
