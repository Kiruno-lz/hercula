import { common } from '@kit.AbilityKit';
import { PreferencesStore } from '../data/PreferencesStore';
import { JsonImportResult, JsonTransfer } from '../data/JsonTransfer';
import {
  buildCalendarCells,
  CalendarCell,
  derivePeriods,
  MenstrualDay,
  PeriodSummary,
  predictNextPeriod
} from '../domain/MenstrualData';
import { formatShortDate, todayKey } from '../domain/DateUtils';

const PINK_BACKGROUND: string = '#F8F2F3';
const CARD_BACKGROUND: string = '#F2E0E3';
const PERIOD_COLOR: string = '#C98291';
const ACCENT_COLOR: string = '#A95E70';
const BLUE_ACCENT: string = '#B8D1D5';
const TEXT_COLOR: string = '#594B50';
const MUTED_TEXT: string = '#8E7B82';

@Entry
@Component
struct Index {
  @State private markedDays: Array<MenstrualDay> = [];
  @State private calendarDate: Date = new Date();
  @State private calendarPagerIndex: number = 1;
  @State private currentPage: number = 0;
  @State private feedback: string = '';
  @State private jumpMode: string = '';
  private store: PreferencesStore | undefined;

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
    }
  }

  private showWelcomeDialog(): void {
    AlertDialog.show({
      title: '欢迎使用月迹',
      message: '点击任意日期即可记录经期，再次点击即可取消。你也可以从历史页导入已有记录。',
      primaryButton: {
        value: '开始记录',
        action: (): void => {}
      },
      secondaryButton: {
        value: '导入数据',
        action: (): void => {
          this.importJson();
        }
      }
    });
  }

  private async toggleDate(date: string): Promise<void> {
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

  private moveMonth(offset: number): void {
    this.calendarDate = new Date(this.calendarDate.getFullYear(), this.calendarDate.getMonth() + offset, 1);
    this.jumpMode = '';
  }

  private onCalendarSwipe(index: number): void {
    if (index === 0) {
      this.moveMonth(-1);
    } else if (index === 2) {
      this.moveMonth(1);
    }
    this.calendarPagerIndex = 1;
  }

  private toggleJumpMode(mode: string): void {
    this.jumpMode = this.jumpMode === mode ? '' : mode;
  }

  private selectYear(year: number): void {
    this.calendarDate = new Date(year, this.calendarDate.getMonth(), 1);
    this.jumpMode = '';
    this.calendarPagerIndex = 1;
  }

  private selectMonth(month: number): void {
    this.calendarDate = new Date(this.calendarDate.getFullYear(), month, 1);
    this.jumpMode = '';
    this.calendarPagerIndex = 1;
  }

  build() {
    Swiper() {
      this.buildCalendarPage();
      this.buildHistoryPage();
    }
    .index(this.currentPage)
    .vertical(true)
    .loop(false)
    .onChange((index: number): void => {
      this.currentPage = index;
    })
    .width('100%')
    .height('100%')
    .backgroundColor(PINK_BACKGROUND)
  }

  @Builder
  private buildCalendarPage() {
    Column() {
      Row() {
        Column({ space: 2 }) {
          Text('月迹')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_COLOR)
          Text('hercula')
            .fontSize(11)
            .fontColor(ACCENT_COLOR)
            .letterSpacing(2)
        }
        Blank()
        Text(`${this.markedDays.length} 天已记录`)
          .fontSize(12)
          .fontColor(ACCENT_COLOR)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .borderRadius(18)
          .backgroundColor('#F2E0E3')
      }
      .width('100%')

      Column({ space: 12 }) {
        Row({ space: 8 }) {
          Button(`${this.calendarDate.getFullYear()}年`)
            .fontSize(16)
            .fontColor(TEXT_COLOR)
            .backgroundColor('#FFF9F9')
            .borderRadius(18)
            .height(38)
            .onClick((): void => this.toggleJumpMode('year'))
          Button(`${this.calendarDate.getMonth() + 1}月`)
            .fontSize(16)
            .fontColor(TEXT_COLOR)
            .backgroundColor('#FFF9F9')
            .borderRadius(18)
            .height(38)
            .onClick((): void => this.toggleJumpMode('month'))
          Blank()
        }
        .width('100%')

        this.buildJumpPanel()

        Swiper() {
          this.buildCalendarMonth(this.calendarDateForOffset(-1))
          this.buildCalendarMonth(this.calendarDate)
          this.buildCalendarMonth(this.calendarDateForOffset(1))
        }
        .index(this.calendarPagerIndex)
        .loop(false)
        .height(274)
        .width('100%')
        .onChange((index: number): void => this.onCalendarSwipe(index))
      }
      .padding({ left: 18, right: 18, top: 18, bottom: 16 })
      .borderRadius(30)
      .backgroundColor(CARD_BACKGROUND)
      .width('100%')
      .constraintSize({ maxWidth: 720 })

      if (this.feedback.length > 0) {
        Text(this.feedback)
          .fontSize(13)
          .fontColor(ACCENT_COLOR)
          .height(20)
      } else {
        Blank().height(20)
      }
    }
    .padding({ left: 20, right: 20, top: 28, bottom: 20 })
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildJumpPanel() {
    if (this.jumpMode === 'year') {
      Grid() {
        ForEach(this.yearOptions(), (year: number) => {
          GridItem() {
            Button(`${year}`)
              .fontSize(13)
              .fontColor(year === this.calendarDate.getFullYear() ? ACCENT_COLOR : TEXT_COLOR)
              .backgroundColor(year === this.calendarDate.getFullYear() ? '#E9C9D0' : '#FFF9F9')
              .borderRadius(14)
              .height(32)
              .width('100%')
              .onClick((): void => this.selectYear(year))
          }
        }, (year: number): string => `${year}`)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(6)
      .columnsGap(6)
      .height(114)
      .width('100%')
    } else if (this.jumpMode === 'month') {
      Grid() {
        ForEach(this.monthOptions(), (month: number) => {
          GridItem() {
            Button(`${month}月`)
              .fontSize(13)
              .fontColor(month === this.calendarDate.getMonth() + 1 ? ACCENT_COLOR : TEXT_COLOR)
              .backgroundColor(month === this.calendarDate.getMonth() + 1 ? '#E9C9D0' : '#FFF9F9')
              .borderRadius(14)
              .height(32)
              .width('100%')
              .onClick((): void => this.selectMonth(month - 1))
          }
        }, (month: number): string => `${month}`)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(6)
      .columnsGap(6)
      .height(114)
      .width('100%')
    }
  }

  @Builder
  private buildCalendarMonth(date: Date) {
    Grid() {
      ForEach(buildCalendarCells(date.getFullYear(), date.getMonth()), (cell: CalendarCell) => {
        GridItem() {
          Row() {
            Text(`${cell.day}`)
              .fontSize(15)
              .fontColor(this.dayTextColor(cell))
              .textAlign(TextAlign.Center)
              .width(38)
              .height(38)
              .borderRadius(19)
              .border({ width: this.isToday(cell.date) ? 2 : 0, color: BLUE_ACCENT })
              .backgroundColor(this.dayColor(cell.date))
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')
          .height(40)
        }
        .onClick((): void => {
          this.toggleDate(cell.date);
        })
      }, (cell: CalendarCell): string => cell.key)
    }
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
    .rowsGap(4)
    .columnsGap(2)
    .width('100%')
    .height(260)
  }

  @Builder
  private buildHistoryPage() {
    Column({ space: 16 }) {
      Text('月经历史')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_COLOR)
        .width('100%')

      Text(`${this.currentPeriods().length} 次记录`)
        .fontSize(13)
        .fontColor(MUTED_TEXT)
        .width('100%')

      if (this.currentPeriods().length === 0) {
        Column({ space: 10 }) {
          Text('还没有历史记录')
            .fontSize(17)
            .fontColor(TEXT_COLOR)
          Text('记录几天后，这里会显示经期变化')
            .fontSize(14)
            .fontColor(MUTED_TEXT)
        }
        .justifyContent(FlexAlign.Center)
        .height(220)
        .width('100%')
      } else {
        Column({ space: 14 }) {
          ForEach(this.currentPeriods().slice(-8), (period: PeriodSummary) => {
            this.buildPeriodRow(period)
          }, (period: PeriodSummary): string => period.startDate)
        }
        .width('100%')
      }

      Column({ space: 8 }) {
        Text('下一次预计')
          .fontSize(14)
          .fontColor(ACCENT_COLOR)
        Text(this.currentPrediction().label)
          .fontSize(18)
          .fontColor(TEXT_COLOR)
        Text('根据已记录历史估算，仅供记录参考')
          .fontSize(12)
          .fontColor(MUTED_TEXT)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Row({ space: 12 }) {
        Button('导入')
          .layoutWeight(1)
          .height(46)
          .fontColor(ACCENT_COLOR)
          .backgroundColor('#EAD1D6')
          .borderRadius(23)
          .onClick((): void => {
            this.importJson();
          })
        Button('导出')
          .layoutWeight(1)
          .height(46)
          .fontColor(Color.White)
          .backgroundColor(ACCENT_COLOR)
          .borderRadius(23)
          .onClick((): void => {
            this.exportJson();
          })
      }
      .width('100%')

      Text(this.feedback)
        .fontSize(13)
        .fontColor(MUTED_TEXT)
        .height(20)
    }
    .padding({ left: 20, right: 20, top: 28, bottom: 20 })
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildPeriodRow(period: PeriodSummary) {
    Row({ space: 8 }) {
      Text(formatShortDate(period.startDate))
        .fontSize(12)
        .fontColor(TEXT_COLOR)
        .width(58)
      Row({ space: 8 }) {
        Row()
          .height(18)
          .width(`${this.periodRatio(period) * 100}%`)
          .borderRadius(9)
          .backgroundColor(period.ongoing ? ACCENT_COLOR : PERIOD_COLOR)
        Text(period.ongoing ? '进行中' : `${period.durationDays}天`)
          .fontSize(12)
          .fontColor(period.ongoing ? ACCENT_COLOR : TEXT_COLOR)
          .maxLines(1)
      }
      .layoutWeight(1)
    }
    .width('100%')
  }

  private calendarDateForOffset(offset: number): Date {
    return new Date(this.calendarDate.getFullYear(), this.calendarDate.getMonth() + offset, 1);
  }

  private yearOptions(): Array<number> {
    const currentYear: number = this.calendarDate.getFullYear();
    return [currentYear - 5, currentYear - 4, currentYear - 3, currentYear - 2, currentYear - 1,
      currentYear, currentYear + 1, currentYear + 2, currentYear + 3, currentYear + 4, currentYear + 5, currentYear + 6];
  }

  private monthOptions(): Array<number> {
    return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  }

  private currentPeriods(): Array<PeriodSummary> {
    return derivePeriods(this.markedDays, todayKey());
  }

  private currentPrediction() {
    return predictNextPeriod(this.currentPeriods());
  }

  private periodRatio(period: PeriodSummary): number {
    let maxDuration: number = 1;
    this.currentPeriods().forEach((item: PeriodSummary): void => {
      maxDuration = Math.max(maxDuration, item.durationDays);
    });
    return Math.max(period.durationDays / maxDuration, 0.08);
  }

  private dayColor(date: string): string {
    return this.hasDate(date) ? PERIOD_COLOR : 'transparent';
  }

  private dayTextColor(cell: CalendarCell): string {
    if (this.hasDate(cell.date)) {
      return '#FFFFFF';
    }
    if (this.isToday(cell.date)) {
      return ACCENT_COLOR;
    }
    return cell.inCurrentMonth ? TEXT_COLOR : '#B9A9AE';
  }

  private isToday(date: string): boolean {
    return date === todayKey();
  }

  private hasDate(date: string): boolean {
    return this.markedDays.some((item: MenstrualDay): boolean => item.date === date);
  }

  private async importJson(): Promise<void> {
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const result: JsonImportResult | undefined = await JsonTransfer.import(context);
      if (result === undefined) {
        this.feedback = '未导入文件，原有记录未改变';
        return;
      }
      const existingDates: Set<string> = new Set<string>();
      this.markedDays.forEach((item: MenstrualDay): void => {
        existingDates.add(item.date);
      });
      const newCount: number = result.days.filter((item: MenstrualDay): boolean => !existingDates.has(item.date)).length;
      AlertDialog.show({
        title: '导入预览',
        message: `文件中有 ${result.days.length} 个有效日期，将新增 ${newCount} 个日期。`,
        primaryButton: {
          value: '取消',
          action: (): void => {}
        },
        secondaryButton: {
          value: '确认导入',
          action: (): void => {
            this.applyImportedDays(result.days);
          }
        }
      });
    } catch (_error) {
      this.feedback = '导入失败：请确认文件是月迹 JSON';
    }
  }

  private async applyImportedDays(days: Array<MenstrualDay>): Promise<void> {
    this.markedDays = this.markedDays.concat(days);
    await this.persistDays();
    this.feedback = `已导入并合并 ${days.length} 个日期`;
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
}
