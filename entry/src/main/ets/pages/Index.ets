import { Context } from '@kit.AbilityKit';
import { PreferencesStore } from '../data/PreferencesStore';
import {
  buildCalendarCells,
  CalendarCell,
  derivePeriods,
  MenstrualDay,
  PeriodSummary,
  predictNextPeriod
} from '../domain/MenstrualData';
import { formatShortDate, monthTitle, todayKey } from '../domain/DateUtils';

const PINK_BACKGROUND: string = '#F7F1F2';
const CARD_BACKGROUND: string = '#F1DDE1';
const PERIOD_COLOR: string = '#C98291';
const ACCENT_COLOR: string = '#A95E70';
const BLUE_ACCENT: string = '#B8D1D5';
const TEXT_COLOR: string = '#594B50';

@Entry
@Component
struct Index {
  @State private markedDays: Array<MenstrualDay> = [];
  @State private calendarDate: Date = new Date();
  @State private currentPage: number = 0;
  @State private feedback: string = '';
  private store: PreferencesStore | undefined;

  aboutToAppear(): void {
    this.loadLocalData();
  }

  private async loadLocalData(): Promise<void> {
    try {
      const context: Context = getContext(this) as Context;
      this.store = await PreferencesStore.open(context);
      this.markedDays = await this.store.loadDays();
    } catch (_error) {
      this.feedback = '本地记录读取失败，当前仅显示空白记录';
    }
  }

  private async toggleToday(): Promise<void> {
    const today: string = todayKey();
    const exists: boolean = this.markedDays.some((item: MenstrualDay): boolean => item.date === today);
    if (exists) {
      AlertDialog.show({
        title: '撤销今天的记录？',
        message: '撤销后，今天不会计入经期统计。',
        primaryButton: {
          value: '保留',
          action: (): void => {}
        },
        secondaryButton: {
          value: '撤销',
          action: (): void => {
            this.markedDays = this.markedDays.filter((item: MenstrualDay): boolean => item.date !== today);
            this.persistDays();
          }
        }
      });
      return;
    }
    const newDay: MenstrualDay = { date: today, source: 'manual' };
    this.markedDays = this.markedDays.concat([newDay]);
    await this.persistDays();
    this.feedback = '今天已记录';
  }

  private async persistDays(): Promise<void> {
    if (this.store !== undefined) {
      await this.store.saveDays(this.markedDays);
    }
  }

  private moveMonth(offset: number): void {
    this.calendarDate = new Date(this.calendarDate.getFullYear(), this.calendarDate.getMonth() + offset, 1);
  }

  private pageIndicator(): string {
    return this.currentPage === 0 ? '向上滑动查看历史 ↓' : '向下滑动返回日历 ↑';
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
    Column({ space: 18 }) {
      Row() {
        Text('月迹')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_COLOR)
        Blank()
        Text('hercula')
          .fontSize(13)
          .fontColor(ACCENT_COLOR)
      }
      .width('100%')

      Column({ space: 18 }) {
        Text('今天，记录身体，也记录时间')
          .fontSize(18)
          .fontColor(TEXT_COLOR)
          .width('100%')

        Row() {
          Button('‹')
            .fontSize(24)
            .fontColor(ACCENT_COLOR)
            .backgroundColor(Color.Transparent)
            .onClick((): void => this.moveMonth(-1))
          Blank()
          Text(monthTitle(this.calendarDate))
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(TEXT_COLOR)
          Blank()
          Button('›')
            .fontSize(24)
            .fontColor(ACCENT_COLOR)
            .backgroundColor(Color.Transparent)
            .onClick((): void => this.moveMonth(1))
        }
        .width('100%')

        Row() {
          ForEach(['一', '二', '三', '四', '五', '六', '日'], (day: string) => {
            Text(day)
              .fontSize(13)
              .fontColor(ACCENT_COLOR)
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
          })
        }
        .width('100%')

        Grid() {
          ForEach(this.calendarCells(), (cell: CalendarCell) => {
            GridItem() {
              Text(`${cell.day}`)
                .fontSize(16)
                .fontColor(cell.inCurrentMonth ? TEXT_COLOR : '#B9A9AE')
                .textAlign(TextAlign.Center)
                .width(34)
                .height(34)
                .borderRadius(17)
                .backgroundColor(this.dayColor(cell.date))
            }
          }, (cell: CalendarCell): string => cell.key)
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
        .rowsGap(10)
        .columnsGap(2)
        .width('100%')
      }
      .padding(20)
      .borderRadius(28)
      .backgroundColor(CARD_BACKGROUND)
      .width('100%')

      Button(this.todayButtonLabel())
        .fontSize(16)
        .fontColor(Color.White)
        .backgroundColor(ACCENT_COLOR)
        .borderRadius(22)
        .height(46)
        .width('100%')
        .onClick((): void => this.toggleToday())

      if (this.feedback.length > 0) {
        Text(this.feedback)
          .fontSize(14)
          .fontColor(ACCENT_COLOR)
      }

      Text(this.pageIndicator())
        .fontSize(13)
        .fontColor('#8E7B82')
    }
    .padding({ left: 20, right: 20, top: 28, bottom: 20 })
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildHistoryPage() {
    const periods: Array<PeriodSummary> = derivePeriods(this.markedDays, todayKey());
    const prediction = predictNextPeriod(periods);
    Column({ space: 18 }) {
      Text('月经历史')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_COLOR)
        .width('100%')
      Text(`${periods.length} 次记录 · 无边框水平统计`)
        .fontSize(14)
        .fontColor('#8E7B82')
        .width('100%')

      if (periods.length === 0) {
        Column({ space: 10 }) {
          Text('先记录今天，月迹会慢慢形成')
            .fontSize(17)
            .fontColor(TEXT_COLOR)
          Text('每条水平柱的末端会显示持续天数')
            .fontSize(14)
            .fontColor('#8E7B82')
        }
        .justifyContent(FlexAlign.Center)
        .height(220)
        .width('100%')
      } else {
        Column({ space: 14 }) {
          ForEach(periods.slice(-8), (period: PeriodSummary) => {
            this.buildPeriodRow(period, periods)
          }, (period: PeriodSummary): string => period.startDate)
        }
        .width('100%')
      }

      Column({ space: 8 }) {
        Text('下一次预计')
          .fontSize(14)
          .fontColor(ACCENT_COLOR)
        Text(prediction.label)
          .fontSize(18)
          .fontColor(TEXT_COLOR)
        Text('根据已记录历史估算，仅供记录参考')
          .fontSize(12)
          .fontColor('#8E7B82')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Row({ space: 12 }) {
        Button('导入')
          .layoutWeight(1)
          .height(44)
          .fontColor(ACCENT_COLOR)
          .backgroundColor('#EAD1D6')
          .borderRadius(22)
          .onClick((): void => this.showComingSoon('导入功能将在下一阶段接入'))
        Button('导出')
          .layoutWeight(1)
          .height(44)
          .fontColor(Color.White)
          .backgroundColor(ACCENT_COLOR)
          .borderRadius(22)
          .onClick((): void => this.showComingSoon('导出功能将在下一阶段接入'))
      }
      .width('100%')

      Text(this.feedback.length > 0 ? this.feedback : this.pageIndicator())
        .fontSize(13)
        .fontColor('#8E7B82')
    }
    .padding({ left: 20, right: 20, top: 28, bottom: 20 })
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildPeriodRow(period: PeriodSummary, periods: Array<PeriodSummary>) {
    let maxDuration: number = 1;
    periods.forEach((item: PeriodSummary): void => {
      maxDuration = Math.max(maxDuration, item.durationDays);
    });
    const ratio: number = Math.max(period.durationDays / maxDuration, 0.08);
    Row({ space: 8 }) {
      Text(formatShortDate(period.startDate))
        .fontSize(12)
        .fontColor(TEXT_COLOR)
        .width(58)
      Row({ space: 8 }) {
        Row()
          .height(18)
          .width(`${ratio * 100}%`)
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

  private calendarCells(): Array<CalendarCell> {
    return buildCalendarCells(this.calendarDate.getFullYear(), this.calendarDate.getMonth());
  }

  private dayColor(date: string): string {
    if (date === todayKey() && this.hasDate(date)) {
      return BLUE_ACCENT;
    }
    return this.hasDate(date) ? PERIOD_COLOR : Color.Transparent;
  }

  private hasDate(date: string): boolean {
    return this.markedDays.some((item: MenstrualDay): boolean => item.date === date);
  }

  private todayButtonLabel(): string {
    return this.hasDate(todayKey()) ? '今天已记录 · 再次点击撤销' : '记录今天来月经';
  }

  private showComingSoon(message: string): void {
    this.feedback = message;
  }
}
