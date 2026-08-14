import { common } from '@kit.AbilityKit';
import { PreferencesStore } from '../data/PreferencesStore';
import { JsonImportResult, JsonTransfer } from '../data/JsonTransfer';
import {
  derivePeriods,
  MenstrualDay,
  PeriodSummary,
  predictNextPeriod
} from '../domain/MenstrualData';
import { formatShortDate, todayKey } from '../domain/DateUtils';

const PINK_BACKGROUND: string = '#F8F2F3';
const PERIOD_COLOR: string = '#C98291';
const ACCENT_COLOR: string = '#A95E70';
const TEXT_COLOR: string = '#594B50';
const MUTED_TEXT: string = '#8E7B82';

@Entry
@Component
struct Index {
  @State private markedDays: Array<MenstrualDay> = [];
  @State private calendarDate: Date = new Date();
  @State private calendarRenderVersion: number = 0;
  @State private calendarDragOffset: number = 0;
  @State private calendarViewportWidth: number = 400;
  @State private calendarAnimationDuration: number = 0;
  @State private calendarSwipeSettling: boolean = false;
  @State private currentPage: number = 0;
  @State private feedback: string = '';
  @State private jumpMode: string = '';
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

  private moveMonth(offset: number): void {
    this.calendarDate = new Date(this.calendarDate.getFullYear(), this.calendarDate.getMonth() + offset, 1);
    this.jumpMode = '';
    this.calendarRenderVersion += 1;
  }

  private onCalendarPanUpdate(event: GestureEvent): void {
    if (this.calendarSwipeSettling) {
      return;
    }
    this.calendarAnimationDuration = 0;
    this.calendarDragOffset = Math.max(-this.calendarViewportWidth,
      Math.min(this.calendarViewportWidth, event.offsetX));
  }

  private onCalendarPanEnd(event: GestureEvent): void {
    if (this.calendarSwipeSettling) {
      return;
    }
    const threshold: number = Math.max(40, this.calendarViewportWidth * 0.2);
    if (event.offsetX < -threshold) {
      this.settleCalendarSwipe(1);
    } else if (event.offsetX > threshold) {
      this.settleCalendarSwipe(-1);
    } else {
      this.animateCalendarBack();
    }
  }

  private settleCalendarSwipe(offset: number): void {
    this.calendarSwipeSettling = true;
    this.calendarAnimationDuration = 180;
    this.calendarDragOffset = offset > 0 ? -this.calendarViewportWidth : this.calendarViewportWidth;
    setTimeout((): void => {
      this.calendarAnimationDuration = 0;
      this.moveMonth(offset);
      this.calendarDragOffset = 0;
      this.calendarSwipeSettling = false;
    }, 190);
  }

  private animateCalendarBack(): void {
    this.calendarSwipeSettling = true;
    this.calendarAnimationDuration = 160;
    this.calendarDragOffset = 0;
    setTimeout((): void => {
      this.calendarAnimationDuration = 0;
      this.calendarSwipeSettling = false;
    }, 170);
  }

  private toggleJumpMode(mode: string): void {
    this.jumpMode = this.jumpMode === mode ? '' : mode;
  }

  private selectYear(year: number): void {
    this.calendarDate = new Date(year, this.calendarDate.getMonth(), 1);
    this.jumpMode = '';
    this.calendarRenderVersion += 1;
  }

  private selectMonth(month: number): void {
    this.calendarDate = new Date(this.calendarDate.getFullYear(), month, 1);
    this.jumpMode = '';
    this.calendarRenderVersion += 1;
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
    .indicator(false)
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
            .fontSize(68)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_COLOR)
          Text('hercula')
            .fontSize(24)
            .fontColor(ACCENT_COLOR)
            .letterSpacing(2)
            // .alignSelf(ItemAlign.Start)
        }
        Blank()
      }
      .width('100%')

      Column({ space: 6 }) {
        Row({ space: 8 }) {
          Button(`${this.calendarDate.getFullYear()}年`)
            .fontSize(16)
            .fontColor(TEXT_COLOR)
            .backgroundColor('#FFF9F9')
            .borderRadius(18)
            .height(38)
            .width(74)
            .padding(0)
            .onClick((): void => this.toggleJumpMode('year'))
          Button(`${this.calendarDate.getMonth() + 1}月`)
            .fontSize(16)
            .fontColor(TEXT_COLOR)
            .backgroundColor('#FFF9F9')
            .borderRadius(18)
            .height(38)
            .width(52)
            .padding(0)
            .onClick((): void => this.toggleJumpMode('month'))
          Blank()
        }
        .width('100%')

        Stack() {
          this.buildCalendarCarousel()

          if (this.jumpMode !== '') {
            Stack() {
              this.buildJumpPanel()
            }
            .position({ x: 0, y: 0 })
            .zIndex(2)
            .width('100%')
            .height(183)
            .backgroundColor('#E8FFF9FA')
            .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THICK)
            .backgroundEffect({ radius: 28, saturation: 1.06, brightness: 1.04 })
            .border({ width: 1, color: '#A8FFFFFF' })
            .borderRadius(20)
            .shadow({ radius: 20, color: '#2F9F6270', offsetX: 0, offsetY: 8 })
            .transition(TransitionEffect.OPACITY
              .combine(TransitionEffect.translate({ y: -18 }))
              .animation({ duration: 240, curve: Curve.EaseOut }))
          }
        }
        .height(360)
        .width('100%')
      }
      .padding({ left: 0, right: 0, top: 18, bottom: 0 })
      .width('100%')
      .constraintSize({ maxWidth: 720 })
    }
    .padding({ left: 20, right: 20, top: 120, bottom: 20 })
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
    .radialGradient({
      center: ['50%', '36%'],
      radius: '68%',
      colors: [['#F1DDE1', 0.0], [PINK_BACKGROUND, 1.0]]
    })
  }

  @Builder
  private buildJumpPanel() {
    if (this.jumpMode === 'year') {
      Grid() {
        ForEach(this.yearOptions(), (year: number) => {
          GridItem() {
            Row() {
              Button(`${year}`)
                .fontSize(13)
                .fontColor(year === this.calendarDate.getFullYear() ? ACCENT_COLOR : TEXT_COLOR)
                .backgroundColor(year === this.calendarDate.getFullYear() ? '#E9C9D0' : '#FFF9F9')
                .borderRadius(14)
                .height(28)
                .width('60%')
                .padding(0)
                .onClick((): void => this.selectYear(year))
            }
            .justifyContent(FlexAlign.Center)
            .width('100%')
            .height('100%')
          }
        }, (year: number): string => `${year}`)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr')
      .rowsGap(8)
      .columnsGap(4)
      .padding({ left: 18, right: 18, top: 10, bottom: 10 })
      .height(183)
      .width('100%')
    } else if (this.jumpMode === 'month') {
      Grid() {
        ForEach(this.monthOptions(), (month: number) => {
          GridItem() {
            Row() {
              Button(`${month}月`)
                .fontSize(13)
                .fontColor(month === this.calendarDate.getMonth() + 1 ? ACCENT_COLOR : TEXT_COLOR)
                .backgroundColor(month === this.calendarDate.getMonth() + 1 ? '#E9C9D0' : '#FFF9F9')
                .borderRadius(14)
                .height(26)
                .width('60%')
                .padding(0)
                .onClick((): void => this.selectMonth(month - 1))
            }
            .justifyContent(FlexAlign.Center)
            .width('100%')
            .height('100%')
          }
        }, (month: number): string => `${month}`)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr')
      .rowsGap(8)
      .columnsGap(4)
      .padding({ left: 18, right: 18, top: 10, bottom: 10 })
      .height(183)
      .width('100%')
    }
  }

  @Builder
  private buildCalendarCarousel() {
    Stack() {
      if (this.calendarRenderVersion % 2 === 0) {
        this.buildCalendarTrackA()
      } else {
        this.buildCalendarTrackB()
      }
    }
    .clip(true)
    .width('100%')
    .height(360)
    .onAreaChange((_oldValue: Area, newValue: Area): void => {
      this.calendarViewportWidth = newValue.width as number;
    })
    .gesture(
      PanGesture({ direction: PanDirection.Horizontal })
        .onActionUpdate((event: GestureEvent): void => this.onCalendarPanUpdate(event))
        .onActionEnd((event: GestureEvent): void => this.onCalendarPanEnd(event))
    )
  }

  @Builder
  private buildCalendarTrackA() {
    Stack() {
      this.buildCalendarMonthCardA(-1)
      this.buildCalendarMonthCardA(0)
      this.buildCalendarMonthCardA(1)
    }
    .width('100%')
    .height(360)
  }

  @Builder
  private buildCalendarTrackB() {
    Stack() {
      this.buildCalendarMonthCardB(-1)
      this.buildCalendarMonthCardB(0)
      this.buildCalendarMonthCardB(1)
    }
    .width('100%')
    .height(360)
  }

  @Builder
  private buildCalendarMonthCardA(offset: number) {
    Column() {
      this.buildCalendarMonthA(offset)
    }
    .width('100%')
    .height(360)
    .margin({ top: 22 })
    .translate({ x: offset * this.calendarViewportWidth + this.calendarDragOffset })
    .animation({ duration: this.calendarAnimationDuration, curve: Curve.EaseOut })
  }

  @Builder
  private buildCalendarMonthCardB(offset: number) {
    Column() {
      this.buildCalendarMonthB(offset)
    }
    .width('100%')
    .height(360)
    .margin({ top: 22 })
    .translate({ x: offset * this.calendarViewportWidth + this.calendarDragOffset })
    .animation({ duration: this.calendarAnimationDuration, curve: Curve.EaseOut })
  }

  @Builder
  private buildCalendarMonthA(offset: number) {
    Grid() {
      ForEach(this.calendarDayNumbersForOffset(offset), (day: number) => {
        this.buildCalendarDay(offset, day)
      }, (day: number): string => this.calendarDayKey(offset, day))
    }
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
    .rowsGap(15)
    .columnsGap(2)
    .width('100%')
    .height(360)
    .id(`calendar-grid-a-${this.calendarRenderVersion}-${offset}`)
  }

  @Builder
  private buildCalendarMonthB(offset: number) {
    Grid() {
      ForEach(this.calendarDayNumbersForOffset(offset), (day: number) => {
        this.buildCalendarDay(offset, day)
      }, (day: number): string => this.calendarDayKey(offset, day))
    }
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
    .rowsGap(15)
    .columnsGap(2)
    .width('100%')
    .height(360)
    .id(`calendar-grid-b-${this.calendarRenderVersion}-${offset}`)
  }

  @Builder
  private buildCalendarDay(offset: number, day: number) {
    GridItem() {
      Row() {
        Text(`${day}`)
          .fontSize(15)
          .fontColor(this.dayTextColor(this.calendarDayKey(offset, day)))
          .textAlign(TextAlign.Center)
          .width(38)
          .height(38)
          .borderRadius(19)
          .backgroundColor(this.dayColor(this.calendarDayKey(offset, day)))
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height(40)
    }
    .visibility(this.isCalendarDayVisible(offset, day) ? Visibility.Visible : Visibility.Hidden)
    .onClick((): void => {
      this.toggleDate(this.calendarDayKey(offset, day));
    })
  }

  @Builder
  private buildHistoryPage() {
    Scroll() {
      Column({ space: 16 }) {
        Row() {
          Text('月经历史')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_COLOR)
            .layoutWeight(1)
          Button() {
            Image($r('app.media.history_export'))
              .width(24)
              .height(24)
          }
          .backgroundColor('#FFF9F9')
          .borderRadius(22)
          .width(44)
          .height(44)
          .padding(0)
          .onClick((): void => {
            this.exportJson();
          })
        }
        .width('100%')
        .height(44)

        Column({ space: 8 }) {
          Text('下一次预计')
            .fontSize(14)
            .fontColor(ACCENT_COLOR)
          Text(this.currentPrediction().label)
            .fontSize(18)
            .fontColor(TEXT_COLOR)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        if (this.currentPeriods().length === 0) {
          Column({ space: 10 }) {
            Text('还没有历史记录')
              .fontSize(17)
              .fontColor(TEXT_COLOR)
            Text('记录几天后，这里会显示经期变化')
              .fontSize(14)
              .fontColor(MUTED_TEXT)
            Button('导入已有记录')
              .fontSize(14)
              .fontColor(ACCENT_COLOR)
              .backgroundColor('#EAD1D6')
              .borderRadius(20)
              .height(40)
              .padding({ left: 20, right: 20 })
              .onClick((): void => {
                this.importJson();
              })
          }
          .justifyContent(FlexAlign.Center)
          .height(220)
          .width('100%')
        } else {
          Column({ space: 14 }) {
            ForEach(this.currentPeriodsDescending(), (period: PeriodSummary) => {
              this.buildHistoryPeriodItem(period)
            }, (period: PeriodSummary): string => period.startDate)
          }
          .width('100%')
        }
      }
      .padding({ left: 20, right: 20, top: 28, bottom: 20 })
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .nestedScroll({
      scrollForward: NestedScrollMode.SELF_FIRST,
      scrollBackward: NestedScrollMode.SELF_FIRST
    })
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
          .margin({ left: this.periodBarOffset(period) })
          .width(`${this.periodRatio(period) * 82}%`)
          .borderRadius(9)
          .backgroundColor(period.ongoing ? ACCENT_COLOR : PERIOD_COLOR)
        Text(period.ongoing ? '进行中' : `${period.durationDays}天`)
          .fontSize(12)
          .fontColor(period.ongoing ? ACCENT_COLOR : TEXT_COLOR)
          .maxLines(1)
      }
      .layoutWeight(1)
      .height(24)
    }
    .width('100%')
  }

  @Builder
  private buildHistoryPeriodItem(period: PeriodSummary) {
    Stack() {
      this.buildPeriodRow(period)
      if (this.shouldShowYearDivider(period)) {
        Text(`${this.periodYear(period)}年`)
          .fontSize(12)
          .fontColor('#B9A7AD')
          .position({ x: 0, y: -14 })
      }
    }
    .width('100%')
    .height(24)
  }

  private calendarDateForOffset(offset: number): Date {
    return new Date(this.calendarDate.getFullYear(), this.calendarDate.getMonth() + offset, 1);
  }

  private calendarDayNumbersForOffset(offset: number): Array<number> {
    const days: Array<number> = [];
    const count: number = this.monthDayCount(this.calendarDateForOffset(offset));
    for (let day: number = 1; day <= count; day += 1) {
      days.push(day);
    }
    return days;
  }

  private monthDayCount(date: Date): number {
    const year = date.getFullYear();
    const month = date.getMonth();
    const monthDays: Array<number> = [31, this.isLeapYear(year) ? 29 : 28, 31, 30, 31, 30,
      31, 31, 30, 31, 30, 31];
    return monthDays[month];
  }

  private calendarDateKey(date: Date, day: number): string {
    const month: number = date.getMonth() + 1;
    return `${date.getFullYear()}-${month < 10 ? '0' : ''}${month}-${day < 10 ? '0' : ''}${day}`;
  }

  private calendarDayKey(offset: number, day: number): string {
    return this.calendarDateKey(this.calendarDateForOffset(offset), day);
  }

  private isCalendarDayVisible(offset: number, day: number): boolean {
    return day <= this.monthDayCount(this.calendarDateForOffset(offset));
  }

  private yearOptions(): Array<number> {
    const currentYear: number = this.calendarDate.getFullYear();
    return [currentYear - 5, currentYear - 4, currentYear - 3, currentYear - 2, currentYear - 1,
      currentYear, currentYear + 1, currentYear + 2, currentYear + 3, currentYear + 4, currentYear + 5, currentYear + 6];
  }

  private monthOptions(): Array<number> {
    return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  }

  private isLeapYear(year: number): boolean {
    return year % 4 === 0 && (year % 100 !== 0 || year % 400 === 0);
  }

  private currentPeriods(): Array<PeriodSummary> {
    return derivePeriods(this.markedDays, todayKey());
  }

  private currentPeriodsDescending(): Array<PeriodSummary> {
    return this.currentPeriods().slice().sort((left: PeriodSummary, right: PeriodSummary): number => {
      if (left.startDate === right.startDate) {
        return 0;
      }
      return left.startDate < right.startDate ? 1 : -1;
    });
  }

  private periodYear(period: PeriodSummary): string {
    return period.startDate.split('-')[0];
  }

  private shouldShowYearDivider(period: PeriodSummary): boolean {
    const periods: Array<PeriodSummary> = this.currentPeriodsDescending();
    for (let index: number = 1; index < periods.length; index += 1) {
      if (periods[index].startDate === period.startDate) {
        return this.periodYear(periods[index - 1]) !== this.periodYear(period);
      }
    }
    return false;
  }

  private periodBarOffset(period: PeriodSummary): number {
    return period.durationDays <= 2 ? 3 : 0;
  }

  private currentPrediction() {
    return predictNextPeriod(this.currentPeriods());
  }

  private periodRatio(period: PeriodSummary): number {
    return period.durationDays / this.periodScaleMax();
  }

  private periodScaleMax(): number {
    let maxDuration: number = 1;
    this.currentPeriods().forEach((item: PeriodSummary): void => {
      maxDuration = Math.max(maxDuration, item.durationDays);
    });
    return maxDuration;
  }

  private dayColor(date: string): string {
    return this.hasDate(date) ? PERIOD_COLOR : 'transparent';
  }

  private dayTextColor(date: string): string {
    if (this.hasDate(date)) {
      return '#FFFFFF';
    }
    return TEXT_COLOR;
  }

  private isToday(date: string): boolean {
    return date === todayKey();
  }

  private hasDate(date: string): boolean {
    return this.markedDays.some((item: MenstrualDay): boolean => item.date === date);
  }

  private isFutureDate(date: string): boolean {
    return date > todayKey();
  }

  private async importJson(): Promise<void> {
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const result: JsonImportResult | undefined = await JsonTransfer.import(context);
      if (result === undefined) {
        this.feedback = '未导入文件，原有记录未改变';
        return;
      }
      const importableDays: Array<MenstrualDay> = result.days.filter((item: MenstrualDay): boolean => {
        return !this.isFutureDate(item.date);
      });
      if (importableDays.length === 0) {
        this.feedback = '导入失败：文件中没有今天或更早的经期日';
        return;
      }
      const existingDates: Set<string> = new Set<string>();
      this.markedDays.forEach((item: MenstrualDay): void => {
        existingDates.add(item.date);
      });
      const newCount: number = importableDays.filter((item: MenstrualDay): boolean => {
        return !existingDates.has(item.date);
      }).length;
      AlertDialog.show({
        title: '导入预览',
        message: `文件中有 ${importableDays.length} 个有效日期，将新增 ${newCount} 个日期。`,
        primaryButton: {
          value: '取消',
          action: (): void => {}
        },
        secondaryButton: {
          value: '确认导入',
          action: (): void => {
            this.applyImportedDays(importableDays);
          }
        }
      });
    } catch (_error) {
      this.feedback = '导入失败：请确认文件是月迹 JSON';
    }
  }

  private async applyImportedDays(days: Array<MenstrualDay>): Promise<void> {
    const importableDays: Array<MenstrualDay> = days.filter((item: MenstrualDay): boolean => {
      return !this.isFutureDate(item.date);
    });
    this.markedDays = this.markedDays.concat(importableDays);
    await this.persistDays();
    this.feedback = `已导入并合并 ${importableDays.length} 个日期`;
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
