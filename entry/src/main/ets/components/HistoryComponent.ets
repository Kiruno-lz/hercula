import { ActionMenuComponent } from './ActionMenuComponent';
import { formatShortDate, todayKey } from '../domain/DateUtils';
import {
  derivePeriods,
  MenstrualDay,
  PeriodSummary,
  predictNextPeriod
} from '../domain/MenstrualData';

const TEXT_COLOR: string = '#594B50';
const PERIOD_COLOR: string = '#C98291';
const ACCENT_COLOR: string = '#A95E70';
const MUTED_TEXT: string = '#8E7B82';

@Component
export struct HistoryComponent {
  @Prop markedDays: Array<MenstrualDay> = [];
  onImport: () => void = (): void => {};
  onExport: () => void = (): void => {};
  onAbout: () => void = (): void => {};

  @State private actionMenuOpen: boolean = false;

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Scroll() {
        Column({ space: 16 }) {
          Row() {
            Text('月经历史')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(TEXT_COLOR)
              .layoutWeight(1)
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
                  this.onImport();
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
        .padding({ left: 20, right: 20, top: '2.12%', bottom: '1.52%' })
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Center)
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .onClick((): void => {
        if (this.actionMenuOpen) {
          this.actionMenuOpen = false;
        }
      })
      .nestedScroll({
        scrollForward: NestedScrollMode.SELF_FIRST,
        scrollBackward: NestedScrollMode.SELF_FIRST
      })

      Column() {
        Blank()
          .layoutWeight(1)
        Row() {
          ActionMenuComponent({
            actionMenuOpen: this.actionMenuOpen,
            onOpenChange: (open: boolean): void => {
              this.actionMenuOpen = open;
            },
            onImport: (): void => this.onImport(),
            onExport: (): void => this.onExport(),
            onAbout: (): void => this.onAbout()
          })
        }
        .width(184)
        .height(44)
        .margin({ right: '1.52%', bottom: '1.52%' })
      }
      .alignItems(HorizontalAlign.End)
      .hitTestBehavior(HitTestMode.Transparent)
      .position({ x: 0, y: 0 })
      .width('100%')
      .height('100%')
      .zIndex(5)
    }
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
}
