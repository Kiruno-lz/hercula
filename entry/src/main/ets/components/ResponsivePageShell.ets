import { ActionMenuComponent } from './ActionMenuComponent';
import { MenstrualDay } from '../domain/MenstrualData';
import { CalendarComponent } from './CalendarComponent';
import { HistoryComponent } from './HistoryComponent';
import { classifyLayoutMode, PageLayoutMode } from '../domain/ResponsiveLayout';

const PINK_BACKGROUND: string = '#F8F2F3';

@Component
export struct ResponsivePageShell {
  @Prop markedDays: Array<MenstrualDay> = [];
  @Prop viewportWidth: number = 1320;
  @Prop viewportHeight: number = 2120;
  @Prop showLayoutModeDebug: boolean = false;
  onToggleDate: (date: string) => void = (_date: string): void => {};
  onImport: () => void = (): void => {};
  onExport: () => void = (): void => {};
  onAbout: () => void = (): void => {};

  @State private currentPage: number = 0;
  @State private scrollActionMenuOpen: boolean = false;

  build() {
    Stack() {
      if (this.layoutMode() === 'compact') {
        this.buildCompactLayout();
      } else if (this.layoutMode() === 'single') {
        this.buildSingleLayout();
      } else if (this.layoutMode() === 'dual') {
        this.buildDualLayout();
      } else {
        this.buildScrollLayout();
        this.buildScrollActionMenu();
      }

      if (this.showLayoutModeDebug) {
        Text(`${this.layoutMode()} ${this.viewportWidth}×${this.viewportHeight}`)
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

  private layoutMode(): PageLayoutMode {
    return classifyLayoutMode(this.viewportWidth, this.viewportHeight);
  }

  @Builder
  private buildCompactLayout() {
    CalendarComponent({
      markedDays: this.markedDays,
      compact: true,
      onToggleDate: this.onToggleDate
    });
  }

  @Builder
  private buildSingleLayout() {
    Swiper() {
      CalendarComponent({
        markedDays: this.markedDays,
        onToggleDate: this.onToggleDate
      });
      HistoryComponent({
        markedDays: this.markedDays,
        onImport: this.onImport,
        onExport: this.onExport,
        onAbout: this.onAbout
      });
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
    .backgroundColor(PINK_BACKGROUND);
  }

  @Builder
  private buildDualLayout() {
    Row() {
      Column() {
        CalendarComponent({
          markedDays: this.markedDays,
          onToggleDate: this.onToggleDate
        });
      }
      .layoutWeight(1)
      .height('100%');

      Column() {
        HistoryComponent({
          markedDays: this.markedDays,
          onImport: this.onImport,
          onExport: this.onExport,
          onAbout: this.onAbout
        });
      }
      .layoutWeight(1)
      .height('100%');
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  private buildScrollLayout() {
    Scroll() {
      Column() {
        CalendarComponent({
          markedDays: this.markedDays,
          scrollLayout: true,
          onToggleDate: this.onToggleDate
        });
        HistoryComponent({
          markedDays: this.markedDays,
          embeddedInScroll: true,
          showActionMenu: false,
          onImport: this.onImport,
          onExport: this.onExport,
          onAbout: this.onAbout
        });
      }
      .width('100%');
    }
    .scrollable(ScrollDirection.Vertical)
    .width('100%')
    .height('100%');
  }

  @Builder
  private buildScrollActionMenu() {
    Row() {
      ActionMenuComponent({
        actionMenuOpen: this.scrollActionMenuOpen,
        onOpenChange: (open: boolean): void => {
          this.scrollActionMenuOpen = open;
        },
        onImport: this.onImport,
        onExport: this.onExport,
        onAbout: this.onAbout
      });
    }
    .width(184)
    .height(44)
    .margin({ right: '1.52%', bottom: '1.52%' })
    .zIndex(5);
  }
}
