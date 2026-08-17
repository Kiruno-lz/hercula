import { MenstrualDay } from '../domain/MenstrualData';
import { todayKey } from '../domain/DateUtils';
import { resolveRuntimeLayoutMetrics, RuntimeLayoutMetrics } from '../domain/ResponsiveLayout';
import { DEFAULT_THEME_ID, resolveTheme, ThemePalette } from '../domain/Theme';

const DEFAULT_LAYOUT_METRICS: RuntimeLayoutMetrics = resolveRuntimeLayoutMetrics(1320, 2120);
const DEFAULT_THEME: ThemePalette = resolveTheme(DEFAULT_THEME_ID);

@Component
export struct CalendarComponent {
  @Prop markedDays: Array<MenstrualDay> = [];
  @Prop layoutMetrics: RuntimeLayoutMetrics = DEFAULT_LAYOUT_METRICS;
  @Prop theme: ThemePalette = DEFAULT_THEME;
  onToggleDate: (date: string) => void = (_date: string): void => {};

  @State private calendarDate: Date = new Date();
  @State private calendarRenderVersion: number = 0;
  @State private calendarDragOffset: number = 0;
  @State private calendarViewportWidth: number = 400;
  @State private calendarAnimationDuration: number = 0;
  @State private calendarSwipeSettling: boolean = false;
  @State private jumpMode: string = '';

  build() {
    this.buildCalendarPage();
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

  private formatYearLabel(year: number): string {
    if (this.layoutMetrics.viewportWidth < this.layoutMetrics.calendarYearLabelShortThresholdVp) {
      return `${String(year).slice(-2)}年`;
    }
    return `${year}`;
  }

  @Builder
  private buildCalendarPage() {
    Column() {
      if (this.layoutMetrics.mode !== 'compact') {
        Row() {
          Column({ space: 2 }) {
            Text('月迹')
              .fontSize(this.layoutMetrics.calendarTitleFontSizeVp)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.theme.text)
            Text('hercula')
              .fontSize(this.layoutMetrics.calendarSubtitleFontSizeVp)
              .fontColor(this.theme.accent)
              .letterSpacing(2)
          }
          Blank()
        }
        .width(`${this.layoutMetrics.calendarContentWidthRatio * 100}%`)
      }

      Column({ space: this.layoutMetrics.calendarSelectorVerticalGapVp }) {
        Row({ space: this.layoutMetrics.calendarSelectorHorizontalGapVp }) {
          Button(this.formatYearLabel(this.calendarDate.getFullYear()))
            .fontSize(16)
            .fontColor(this.theme.text)
            .backgroundColor(this.theme.selectorBackground)
            .borderRadius(18)
            .height(this.layoutMetrics.calendarSelectorHeightVp)
            .width(this.layoutMetrics.calendarYearButtonWidthVp)
            .padding(0)
            .onClick((): void => this.toggleJumpMode('year'))
          Button(`${this.calendarDate.getMonth() + 1}月`)
            .fontSize(16)
            .fontColor(this.theme.text)
            .backgroundColor(this.theme.selectorBackground)
            .borderRadius(18)
            .height(this.layoutMetrics.calendarSelectorHeightVp)
            .width(this.layoutMetrics.calendarMonthButtonWidthVp)
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
            .height(this.layoutMetrics.calendarJumpPanelHeightVp)
            .backgroundColor(this.theme.glassSurface)
            .backgroundBlurStyle(BlurStyle.Thin, { scale: 0.1 })
            .backgroundEffect({ radius: 28, saturation: 1.06, brightness: 1.04 })
            .border({ width: 1, color: this.theme.glassBorder })
            .borderRadius(20)
            .shadow({ radius: 20, color: this.theme.glassShadow, offsetX: 0, offsetY: 8 })
            .transition(TransitionEffect.OPACITY
              .combine(TransitionEffect.translate({ y: -18 }))
              .animation({ duration: 240, curve: Curve.EaseOut }))
          }
        }
        .height(this.layoutMetrics.calendarGridContainerHeightVp)
        .width(`${this.layoutMetrics.calendarGridWidthRatio * 100}%`)
      }
      .padding({
        left: 0,
        right: 0,
        top: `${this.layoutMetrics.calendarInnerTopInsetRatio * 100}%`,
        bottom: 0
      })
      .width(`${this.layoutMetrics.calendarContentWidthRatio * 100}%`)
      .constraintSize({ maxWidth: 720 })
    }
    .padding({
      left: this.layoutMetrics.calendarHorizontalPaddingVp,
      right: this.layoutMetrics.calendarHorizontalPaddingVp,
      top: this.layoutMetrics.calendarTopInsetVp,
      bottom: this.layoutMetrics.calendarBottomInsetVp
    })
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height(this.layoutMetrics.calendarHeight)
    .radialGradient({
      center: ['50%', '36%'],
      radius: '68%',
      colors: [[this.theme.pageBackgroundDeep, 0.0], [this.theme.pageBackground, 1.0]]
    })
  }

  @Builder
  private buildJumpPanel() {
    if (this.jumpMode === 'year') {
      Grid() {
        ForEach(this.yearOptions(), (year: number) => {
          GridItem() {
            Row() {
              Button(this.formatYearLabel(year))
                .fontSize(13)
                .fontColor(year === this.calendarDate.getFullYear() ? this.theme.accent : this.theme.text)
                .backgroundColor(year === this.calendarDate.getFullYear()
                  ? this.theme.selectorSelectedBackground
                  : this.theme.selectorBackground)
                .borderRadius(14)
                .height(28)
                .width('100%')
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
      .columnsGap(2)
      .padding({ left: 18, right: 18, top: 10, bottom: 10 })
      .height(this.layoutMetrics.calendarJumpPanelHeightVp)
      .width('100%')
    } else if (this.jumpMode === 'month') {
      Grid() {
        ForEach(this.monthOptions(), (month: number) => {
          GridItem() {
            Row() {
              Button(`${month}月`)
                .fontSize(13)
                .fontColor(month === this.calendarDate.getMonth() + 1 ? this.theme.accent : this.theme.text)
                .backgroundColor(month === this.calendarDate.getMonth() + 1
                  ? this.theme.selectorSelectedBackground
                  : this.theme.selectorBackground)
                .borderRadius(14)
                .height(26)
                .width('100%')
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
      .columnsGap(2)
      .padding({ left: 18, right: 18, top: 10, bottom: 10 })
      .height(this.layoutMetrics.calendarJumpPanelHeightVp)
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
    .height(this.layoutMetrics.calendarGridContainerHeightVp)
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
    .height(this.layoutMetrics.calendarGridContainerHeightVp)
  }

  @Builder
  private buildCalendarTrackB() {
    Stack() {
      this.buildCalendarMonthCardB(-1)
      this.buildCalendarMonthCardB(0)
      this.buildCalendarMonthCardB(1)
    }
    .width('100%')
    .height(this.layoutMetrics.calendarGridContainerHeightVp)
  }

  @Builder
  private buildCalendarMonthCardA(offset: number) {
    Column() {
      this.buildCalendarMonthA(offset)
    }
    .width('100%')
    .height(this.layoutMetrics.calendarGridHeightVp)
    .margin({ top: this.layoutMetrics.calendarMonthCardTopInsetVp })
    .translate({ x: offset * this.calendarViewportWidth + this.calendarDragOffset })
    .animation({ duration: this.calendarAnimationDuration, curve: Curve.EaseOut })
  }

  @Builder
  private buildCalendarMonthCardB(offset: number) {
    Column() {
      this.buildCalendarMonthB(offset)
    }
    .width('100%')
    .height(this.layoutMetrics.calendarGridHeightVp)
    .margin({ top: this.layoutMetrics.calendarMonthCardTopInsetVp })
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
    .rowsGap(this.layoutMetrics.calendarGridRowGapVp)
    .columnsGap(this.layoutMetrics.calendarGridColumnGapVp)
    .width('100%')
    .height(this.layoutMetrics.calendarGridHeightVp)
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
    .rowsGap(this.layoutMetrics.calendarGridRowGapVp)
    .columnsGap(this.layoutMetrics.calendarGridColumnGapVp)
    .width('100%')
    .height(this.layoutMetrics.calendarGridHeightVp)
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
          .width(this.layoutMetrics.calendarDateSizeVp)
          .height(this.layoutMetrics.calendarDateSizeVp)
          .borderRadius(19)
          .backgroundColor(this.dayColor(this.calendarDayKey(offset, day)))
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height(this.layoutMetrics.calendarDateRowHeightVp)
    }
    .onClick((): void => {
      const date: string = this.calendarDayKey(offset, day);
      if (!this.isFutureDate(date)) {
        this.onToggleDate(date);
      }
    })
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

  private dayColor(date: string): string {
    return this.hasDate(date) ? this.theme.period : 'transparent';
  }

  private dayTextColor(date: string): string {
    return this.hasDate(date) ? this.theme.periodText : this.theme.text;
  }

  private hasDate(date: string): boolean {
    return this.markedDays.some((item: MenstrualDay): boolean => item.date === date);
  }

  private isFutureDate(date: string): boolean {
    return date > todayKey();
  }
}
