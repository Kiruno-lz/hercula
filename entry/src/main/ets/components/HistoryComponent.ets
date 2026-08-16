import { ActionMenuComponent } from './ActionMenuComponent';
import { formatShortDate, todayKey } from '../domain/DateUtils';
import {
  derivePeriods,
  MenstrualDay,
  PeriodSummary,
  predictNextPeriod
} from '../domain/MenstrualData';
import { resolveRuntimeLayoutMetrics, RuntimeLayoutMetrics } from '../domain/ResponsiveLayout';

const TEXT_COLOR: string = '#594B50';
const PERIOD_COLOR: string = '#C98291';
const ACCENT_COLOR: string = '#A95E70';
const MUTED_TEXT: string = '#8E7B82';
const DEFAULT_LAYOUT_METRICS: RuntimeLayoutMetrics = resolveRuntimeLayoutMetrics(1320, 2120);

@Component
export struct HistoryComponent {
  @Prop markedDays: Array<MenstrualDay> = [];
  @Prop refreshToken: number = 0;
  @Prop embeddedInScroll: boolean = false;
  @Prop compactHistory: boolean = false;
  @Prop showActionMenu: boolean = true;
  @Prop layoutMetrics: RuntimeLayoutMetrics = DEFAULT_LAYOUT_METRICS;
  onImport: () => void = (): void => {};
  onExport: () => void = (): void => {};
  onAbout: () => void = (): void => {};

  @State private actionMenuOpen: boolean = false;

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      if (this.compactHistory) {
        Scroll() {
          this.buildCompactHistoryContent()
        }
        .width('100%')
        .height('100%')
        .nestedScroll({
          scrollForward: NestedScrollMode.SELF_FIRST,
          scrollBackward: NestedScrollMode.SELF_FIRST
        })
      } else if (this.embeddedInScroll) {
        this.buildHistoryContent()
      } else {
        Scroll() {
          this.buildHistoryContent()
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
      }

      if (this.showActionMenu && !this.compactHistory) {
        Column() {
          Blank()
            .layoutWeight(1)
          Row() {
            ActionMenuComponent({
              actionMenuOpen: this.actionMenuOpen,
              layoutMetrics: this.layoutMetrics,
              onOpenChange: (open: boolean): void => {
                this.actionMenuOpen = open;
              },
              onImport: (): void => this.onImport(),
              onExport: (): void => this.onExport(),
              onAbout: (): void => this.onAbout()
            })
          }
          .width(this.layoutMetrics.actionMenuExpandedWidthVp)
          .height(this.layoutMetrics.actionMenuCollapsedSizeVp)
          .margin({
            right: `${this.layoutMetrics.actionMenuRightInsetRatio * 100}%`,
            bottom: `${this.layoutMetrics.actionMenuBottomInsetRatio * 100}%`
          })
        }
        .alignItems(HorizontalAlign.End)
        .hitTestBehavior(HitTestMode.Transparent)
        .position({ x: 0, y: 0 })
        .width('100%')
        .height('100%')
        .zIndex(5)
      }
    }
    .width('100%')
    .height(this.embeddedInScroll ? 'auto' : '100%')
    .id(`history-content-${this.refreshToken}`)
  }

  @Builder
  private buildCompactHistoryContent() {
    Column({ space: this.layoutMetrics.historyPeriodsGapVp }) {
      if (this.currentPeriods().length === 0) {
        Blank()
          .height(200)
          .width('90%')
          .border({ width: 3, style: BorderStyle.Dashed, color: '#D8BFC7' })
          .borderRadius(20)
      } else {
        ForEach(this.currentPeriodsDescending(), (period: PeriodSummary) => {
          this.buildHistoryPeriodItem(period)
        }, (period: PeriodSummary): string => this.periodRenderKey(period))
      }
    }
    .padding({ left: 20, right: 20, top: 24, bottom: 24 })
    .alignItems(HorizontalAlign.Center)
    .width('100%')
  }

  @Builder
  private buildHistoryContent() {
    Column({ space: this.layoutMetrics.historySectionGapVp }) {
      Row() {
        Text('月经历史')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_COLOR)
          .layoutWeight(1)
      }
      .width('100%')
      .height(44)

      Column({ space: this.layoutMetrics.historyPredictionGapVp }) {
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
        .height(200)
        .width('90%')
        .border({ width: 3, style: BorderStyle.Dashed, color: '#D8BFC7' })
        .borderRadius(20)
      } else {
        Column({ space: this.layoutMetrics.historyPeriodsGapVp }) {
          ForEach(this.currentPeriodsDescending(), (period: PeriodSummary) => {
            this.buildHistoryPeriodItem(period)
          }, (period: PeriodSummary): string => this.periodRenderKey(period))
        }
        .width('100%')
      }
    }
    .padding({
      left: 20,
      right: 20,
      top: `${this.layoutMetrics.historyTopInsetRatio * 100}%`,
      bottom: this.layoutMetrics.mode === 'scroll'
        ? this.layoutMetrics.scrollHistoryBottomInsetVp
        : `${this.layoutMetrics.historyBottomInsetRatio * 100}%`
    })
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
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
    const descendingPeriods: Array<PeriodSummary> = this.currentPeriodsDescending();
    const periodIndex: number = descendingPeriods.findIndex((item: PeriodSummary): boolean => {
      return item.startDate === period.startDate;
    });
    if (periodIndex === 0) {
      return this.periodYear(period) !== todayKey().split('-')[0];
    }
    if (periodIndex > 0) {
      return this.periodYear(descendingPeriods[periodIndex - 1]) !== this.periodYear(period);
    }
    return false;
  }

  private periodBarOffset(period: PeriodSummary): number {
    return this.periodRatio(period) < this.layoutMetrics.historyShortBarThresholdRatio
      ? this.layoutMetrics.historyShortBarOffsetVp
      : 0;
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

  private periodRenderKey(period: PeriodSummary): string {
    return `${period.startDate}-${period.durationDays}-${period.ongoing ? 'ongoing' : 'completed'}`;
  }
}
