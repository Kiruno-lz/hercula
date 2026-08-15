import { common } from '@kit.AbilityKit';
import { PreferencesStore } from '../data/PreferencesStore';
import { JsonDateCandidateResult, JsonTransfer } from '../data/JsonTransfer';
import { MenstrualDay } from '../domain/MenstrualData';
import { formatShortDate, todayKey } from '../domain/DateUtils';
import { parseTextDates, TextDateParseResult } from '../domain/TextDateParser';
import { ImportValidationResult, validateImportDates } from '../domain/ImportValidator';
import { CalendarComponent } from '../components/CalendarComponent';
import { HistoryComponent } from '../components/HistoryComponent';
import { WelcomeComponent } from '../components/WelcomeComponent';

const PINK_BACKGROUND: string = '#F8F2F3';
const PERIOD_COLOR: string = '#C98291';
const ACCENT_COLOR: string = '#A95E70';
const TEXT_COLOR: string = '#594B50';
const MUTED_TEXT: string = '#8E7B82';
const IMPORT_DIALOG_HEIGHT: number = 420;
const IMPORT_TEXT_AREA_HEIGHT: number = 148;
const IMPORT_NOTICE_HEIGHT: number = 40;
const ABOUT_DIALOG_HEIGHT: number = 390;
const GITHUB_REPOSITORY_URL: string = 'https://github.com/Kiruno-lz/hercula';

@Entry
@Component
struct Index {
  @State private markedDays: Array<MenstrualDay> = [];
  @State private currentPage: number = 0;
  @State private feedback: string = '';
  @State private welcomeDialogOpen: boolean = false;
  @State private aboutDialogOpen: boolean = false;
  @State private textImportDialogOpen: boolean = false;
  @State private textImportInput: string = '';
  @State private textImportNotice: string = '';
  @State private jsonImportIssues: TextDateParseResult = { dates: [], invalidTokens: [], duplicateDates: [] };
  @State private importConfirmationOpen: boolean = false;
  @State private importValidation: ImportValidationResult = {
    candidateDates: [],
    validDates: [],
    futureDates: [],
    duplicateDates: [],
    existingDates: [],
    invalidTokens: []
  };
  @State private isLoading: boolean = true;
  private store: PreferencesStore | undefined = undefined;

  aboutToAppear(): void {
    this.loadLocalData();
  }

  private async loadLocalData(): Promise<void> {
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      this.store = await PreferencesStore.open(context);
      this.markedDays = await this.store.loadDays();
      if (!(await this.store.hasSeenWelcome())) {
        await this.store.markWelcomeShown();
        this.showWelcomeDialog();
      }
    } catch (_error) {
      this.feedback = '本地记录读取失败，当前仅显示空白记录';
    } finally {
      this.isLoading = false;
    }
  }

  private showWelcomeDialog(): void {
    this.welcomeDialogOpen = true;
  }

  private closeWelcomeDialog(): void {
    this.welcomeDialogOpen = false;
  }

  private async toggleDate(date: string): Promise<void> {
    if (this.isFutureDate(date)) {
      return;
    }
    if (this.hasDate(date)) {
      this.markedDays = this.markedDays.filter((item: MenstrualDay): boolean => item.date !== date);
      this.feedback = `${formatShortDate(date)} 已取消`;
    } else {
      this.markedDays = this.markedDays.concat([{ date: date, source: 'manual' }]);
      this.feedback = `${formatShortDate(date)} 已记录`;
    }
    await this.persistDays();
  }

  private async persistDays(): Promise<void> {
    if (this.store !== undefined) {
      await this.store.saveDays(this.markedDays);
    }
  }

  private openTextImportDialog(): void {
    this.textImportInput = '';
    this.textImportNotice = '';
    this.jsonImportIssues = { dates: [], invalidTokens: [], duplicateDates: [] };
    this.textImportDialogOpen = true;
  }

  private closeTextImportDialog(): void {
    this.textImportDialogOpen = false;
    this.textImportInput = '';
    this.textImportNotice = '';
    this.jsonImportIssues = { dates: [], invalidTokens: [], duplicateDates: [] };
  }

  private async loadJsonIntoTextImport(): Promise<void> {
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const result: JsonDateCandidateResult | undefined = await JsonTransfer.selectDateCandidates(context);
      if (result === undefined) {
        this.textImportNotice = '未选择文件，当前输入内容未改变';
        return;
      }
      this.textImportInput = result.dates.join('\n');
      this.jsonImportIssues = {
        dates: result.dates,
        invalidTokens: result.invalidTokens,
        duplicateDates: result.duplicateDates
      };
      const issueCount: number = result.invalidTokens.length + result.duplicateDates.length;
      this.textImportNotice = issueCount === 0
        ? `已加载 ${result.dates.length} 个日期，可继续校对`
        : `已加载 ${result.dates.length} 个日期，另有 ${issueCount} 项待确认`;
    } catch (_error) {
      this.textImportNotice = 'JSON 解析失败：请确认文件符合月迹 schema v1';
    }
  }

  private continueTextImport(): void {
    const result: TextDateParseResult = parseTextDates(this.textImportInput);
    const validation: ImportValidationResult = validateImportDates({
      dates: result.dates,
      invalidTokens: result.invalidTokens.concat(this.jsonImportIssues.invalidTokens),
      duplicateDates: result.duplicateDates.concat(this.jsonImportIssues.duplicateDates),
      existingDates: this.markedDays.map((item: MenstrualDay): string => item.date),
      today: todayKey()
    });
    if (validation.candidateDates.length === 0 && validation.invalidTokens.length === 0) {
      this.feedback = '请输入至少一个明确格式的日期';
      return;
    }
    this.importValidation = validation;
    this.textImportDialogOpen = false;
    this.importConfirmationOpen = true;
  }

  private closeImportConfirmation(): void {
    this.importConfirmationOpen = false;
    this.textImportDialogOpen = true;
  }

  private resetImportValidation(): void {
    this.importValidation = {
      candidateDates: [],
      validDates: [],
      futureDates: [],
      duplicateDates: [],
      existingDates: [],
      invalidTokens: []
    };
  }

  private async confirmImport(): Promise<void> {
    const days: Array<MenstrualDay> = this.importValidation.validDates.map((date: string): MenstrualDay => {
      return { date: date, source: 'import' };
    });
    if (days.length === 0) {
      this.feedback = '没有可导入的新日期';
      return;
    }
    this.markedDays = this.markedDays.concat(days);
    await this.persistDays();
    this.importConfirmationOpen = false;
    this.closeTextImportDialog();
    this.resetImportValidation();
    this.feedback = `已导入并合并 ${days.length} 个日期`;
  }

  build() {
    Stack() {
      if (this.isLoading) {
        this.buildLoadingPage();
      } else {
        Swiper() {
          CalendarComponent({
            markedDays: this.markedDays,
            onToggleDate: (date: string): void => {
              this.toggleDate(date);
            }
          })
          HistoryComponent({
            markedDays: this.markedDays,
            onImport: (): void => this.openTextImportDialog(),
            onExport: (): void => {
              this.exportJson();
            },
            onAbout: (): void => {
              this.aboutDialogOpen = true;
            }
          })
        }
        .index(this.currentPage)
        .vertical(true)
        .loop(false)
        .onChange((index: number): void => {
          this.currentPage = index;
        })
        .indicator(false)
        .width('100%')
        .height('100%')
        .backgroundColor(PINK_BACKGROUND)
      }
      if (this.textImportDialogOpen) {
        this.buildTextImportDialog();
      }
      if (this.importConfirmationOpen) {
        this.buildImportConfirmationDialog();
      }
      if (this.welcomeDialogOpen) {
        WelcomeComponent({
          onStart: (): void => this.closeWelcomeDialog(),
          onImport: (): void => {
            this.closeWelcomeDialog();
            this.openTextImportDialog();
          }
        })
      }
      if (this.aboutDialogOpen) {
        this.buildAboutDialog();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PINK_BACKGROUND)
  }

  @Builder
  private buildLoadingPage() {
    Column({ space: 22 }) {
      Blank()
      Column({ space: 2 }) {
        Text('月迹')
          .fontSize(52)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_COLOR)
        Text('hercula')
          .fontSize(18)
          .fontColor(ACCENT_COLOR)
          .letterSpacing(2)
      }
      .alignItems(HorizontalAlign.Center)

      Row({ space: 24 }) {
        Circle()
          .width(18)
          .height(18)
          .fill('#E7C6CD')
          .shadow({ radius: 8, color: '#6FC98291', offsetX: 0, offsetY: 2 })
        Circle()
          .width(18)
          .height(18)
          .fill(PERIOD_COLOR)
          .shadow({ radius: 8, color: '#8FC98291', offsetX: 0, offsetY: 2 })
        Circle()
          .width(18)
          .height(18)
          .fill('#D5DEE7')
          .shadow({ radius: 8, color: '#6F9DB3CC', offsetX: 0, offsetY: 2 })
      }

      Text('正在准备记录')
        .fontSize(20)
        .fontColor(ACCENT_COLOR)
      Blank()
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
    .radialGradient({
      center: ['50%', '46%'],
      radius: '74%',
      colors: [['#F1DDE1', 0.0], [PINK_BACKGROUND, 1.0]]
    })
  }

  @Builder
  private buildAboutDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#38F1DDE1')
        .backgroundBlurStyle(BlurStyle.Thin, { scale: 0.1 })
        .onClick((): void => {
          this.aboutDialogOpen = false;
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

        Text(GITHUB_REPOSITORY_URL)
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
        this.aboutDialogOpen = false;
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

  @Builder
  private buildTextImportDialog() {
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
            this.textImportInput = value;
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
            this.loadJsonIntoTextImport();
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
              this.closeTextImportDialog();
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
              this.continueTextImport();
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

  @Builder
  private buildImportConfirmationDialog() {
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
              this.closeImportConfirmation();
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
              this.confirmImport();
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

  private async exportJson(): Promise<void> {
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const saved: boolean = await JsonTransfer.export(context, this.markedDays);
      this.feedback = saved ? '已导出月迹 JSON' : '已取消导出';
    } catch (_error) {
      this.feedback = '导出失败，请稍后重试';
    }
  }

  private hasDate(date: string): boolean {
    return this.markedDays.some((item: MenstrualDay): boolean => item.date === date);
  }

  private isFutureDate(date: string): boolean {
    return date > todayKey();
  }
}
