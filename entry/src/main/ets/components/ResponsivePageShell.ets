import { ActionMenuComponent } from './ActionMenuComponent';
import { MenstrualDay } from '../domain/MenstrualData';
import { CalendarComponent } from './CalendarComponent';
import { HistoryComponent } from './HistoryComponent';
import {
  resolveRuntimeLayoutMetrics,
  RuntimeLayoutMetrics
} from '../domain/ResponsiveLayout';

const PINK_BACKGROUND: string = '#F8F2F3';

@Component
export struct ResponsivePageShell {
  @Prop markedDays: Array<MenstrualDay> = [];
  @Prop dataRevision: number = 0;
  @Prop viewportWidth: number = 1320;
  @Prop viewportHeight: number = 2120;
  @Prop safeAreaTopInset: number = 0;
  @Prop safeAreaBottomInset: number = 0;
  @Prop densityPixels: number = 1;
  @Prop showLayoutModeDebug: boolean = false;
  onToggleDate: (date: string) => void = (_date: string): void => {};
  onImport: () => void = (): void => {};
  onExport: () => void = (): void => {};
  onAbout: () => void = (): void => {};

  @State private currentPage: number = 0;
  @State private scrollActionMenuOpen: boolean = false;

  build() {
    Stack() {
      if (this.layoutMetrics().mode === 'compact') {
        this.buildCompactLayout(this.layoutMetrics());
      } else if (this.layoutMetrics().mode === 'single') {
        this.buildSingleLayout(this.layoutMetrics());
      } else if (this.layoutMetrics().mode === 'dual') {
        this.buildDualLayout(this.layoutMetrics());
      } else {
        this.buildScrollLayout(this.layoutMetrics());
        this.buildScrollActionMenu(this.layoutMetrics());
      }

      if (this.showLayoutModeDebug) {
        Text(`${this.layoutMetrics().mode} ${this.viewportWidth}×${this.viewportHeight}`)
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor('#9C526B')
          .borderRadius(14)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .position({ x: 12, y: 12 })
          .zIndex(20);
      }
    }
    .alignContent(Alignment.BottomEnd)
    .width('100%')
    .height('100%')
    .backgroundColor(PINK_BACKGROUND);
  }

  private layoutMetrics(): RuntimeLayoutMetrics {
    return resolveRuntimeLayoutMetrics(
      this.viewportWidth,
      this.viewportHeight,
      this.safeAreaTopInset,
      this.safeAreaBottomInset,
      this.densityPixels
    );
  }

  @Builder
  private buildCompactLayout(metrics: RuntimeLayoutMetrics) {
    Swiper() {
      CalendarComponent({
        markedDays: this.markedDays,
        compact: true,
        layoutMetrics: metrics,
        onToggleDate: this.onToggleDate
      });
      Column() {
        HistoryComponent({
          markedDays: this.markedDays,
          refreshToken: this.dataRevision,
          compactHistory: true,
          showActionMenu: false,
          layoutMetrics: metrics,
          onImport: this.onImport,
          onExport: this.onExport,
          onAbout: this.onAbout
        });
      }
      .width('100%')
      .height('100%')
      .id(`compact-history-page-${this.dataRevision}`);
    }
    .index(this.currentPage)
    .vertical(true)
    .loop(false)
    .onChange((index: number): void => {
      this.currentPage = index;
    })
    .indicator(false)
    // 历史页依赖 markedDays 的实时派生结果，禁止 Swiper 复用旧的离屏页面。
    .cachedCount(0)
    .width('100%')
    .height('100%')
    .backgroundColor(PINK_BACKGROUND);
  }

  @Builder
  private buildSingleLayout(metrics: RuntimeLayoutMetrics) {
    Swiper() {
      CalendarComponent({
        markedDays: this.markedDays,
        layoutMetrics: metrics,
        onToggleDate: this.onToggleDate
      });
      Column() {
        HistoryComponent({
          markedDays: this.markedDays,
          refreshToken: this.dataRevision,
          layoutMetrics: metrics,
          onImport: this.onImport,
          onExport: this.onExport,
          onAbout: this.onAbout
        });
      }
      .width('100%')
      .height('100%')
      .id(`single-history-page-${this.dataRevision}`);
    }
    .index(this.currentPage)
    .vertical(true)
    .loop(false)
    .onChange((index: number): void => {
      this.currentPage = index;
    })
    .indicator(false)
    .cachedCount(0)
    .width('100%')
    .height('100%')
    .backgroundColor(PINK_BACKGROUND);
  }

  @Builder
  private buildDualLayout(metrics: RuntimeLayoutMetrics) {
    Row() {
      Column() {
        CalendarComponent({
          markedDays: this.markedDays,
          layoutMetrics: metrics,
          onToggleDate: this.onToggleDate
        });
      }
      .layoutWeight(1)
      .height('100%');

      Column() {
        HistoryComponent({
          markedDays: this.markedDays,
          refreshToken: this.dataRevision,
          layoutMetrics: metrics,
          onImport: this.onImport,
          onExport: this.onExport,
          onAbout: this.onAbout
        });
      }
      .layoutWeight(1)
      .height('100%')
      .id(`dual-history-panel-${this.dataRevision}`);
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  private buildScrollLayout(metrics: RuntimeLayoutMetrics) {
    Scroll() {
      Column({ space: metrics.scrollCalendarHistoryGapVp }) {
        CalendarComponent({
          markedDays: this.markedDays,
          scrollLayout: true,
          layoutMetrics: metrics,
          onToggleDate: this.onToggleDate
        });
        Column() {
          HistoryComponent({
            markedDays: this.markedDays,
            refreshToken: this.dataRevision,
            embeddedInScroll: true,
            showActionMenu: false,
            layoutMetrics: metrics,
            onImport: this.onImport,
            onExport: this.onExport,
            onAbout: this.onAbout
          });
        }
        .width('100%')
        .id(`scroll-history-panel-${this.dataRevision}`);
      }
      .width('100%');
    }
    .scrollable(ScrollDirection.Vertical)
    .onClick((): void => {
      if (this.scrollActionMenuOpen) {
        this.scrollActionMenuOpen = false;
      }
    })
    .width('100%')
    .height('100%');
  }

  @Builder
  private buildScrollActionMenu(metrics: RuntimeLayoutMetrics) {
    Row() {
      ActionMenuComponent({
        actionMenuOpen: this.scrollActionMenuOpen,
        layoutMetrics: metrics,
        onOpenChange: (open: boolean): void => {
          this.scrollActionMenuOpen = open;
        },
        onImport: this.onImport,
        onExport: this.onExport,
        onAbout: this.onAbout
      });
    }
    .width(metrics.actionMenuExpandedWidthVp)
    .height(metrics.actionMenuCollapsedSizeVp)
    .margin({
      right: `${metrics.actionMenuRightInsetRatio * 100}%`,
      bottom: `${metrics.actionMenuBottomInsetRatio * 100}%`
    })
    .zIndex(5);
  }
}
