import { MenstrualDay } from '../domain/MenstrualData';
import { CalendarComponent } from './CalendarComponent';
import { HistoryComponent } from './HistoryComponent';

const PINK_BACKGROUND: string = '#F8F2F3';

type PageLayoutMode = 'compact' | 'single' | 'dual';

@Component
export struct ResponsivePageShell {
  @Prop markedDays: Array<MenstrualDay> = [];
  onToggleDate: (date: string) => void = (_date: string): void => {};
  onImport: () => void = (): void => {};
  onExport: () => void = (): void => {};
  onAbout: () => void = (): void => {};

  @State private viewportWidth: number = 1320;
  @State private viewportHeight: number = 2120;
  @State private currentPage: number = 0;

  build() {
    Stack() {
      if (this.layoutMode() === 'compact') {
        CalendarComponent({
          markedDays: this.markedDays,
          compact: true,
          onToggleDate: this.onToggleDate
        })
      } else if (this.layoutMode() === 'dual') {
        Row() {
          Column() {
            CalendarComponent({
              markedDays: this.markedDays,
              onToggleDate: this.onToggleDate
            })
          }
          .layoutWeight(1)
          .height('100%')

          Column() {
            HistoryComponent({
              markedDays: this.markedDays,
              onImport: this.onImport,
              onExport: this.onExport,
              onAbout: this.onAbout
            })
          }
          .layoutWeight(1)
          .height('100%')
        }
        .width('100%')
        .height('100%')
      } else {
        Swiper() {
          CalendarComponent({
            markedDays: this.markedDays,
            onToggleDate: this.onToggleDate
          })
          HistoryComponent({
            markedDays: this.markedDays,
            onImport: this.onImport,
            onExport: this.onExport,
            onAbout: this.onAbout
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PINK_BACKGROUND)
    .onAreaChange((_oldValue: Area, newValue: Area): void => {
      const width: number = newValue.width as number;
      const height: number = newValue.height as number;
      if (width !== this.viewportWidth || height !== this.viewportHeight) {
        this.viewportWidth = width;
        this.viewportHeight = height;
      }
    })
  }

  private layoutMode(): PageLayoutMode {
    const aspectRatio: number = this.viewportWidth / Math.max(1, this.viewportHeight);
    if (aspectRatio >= 0.82 && aspectRatio <= 1.22) {
      return 'compact';
    }
    if (aspectRatio > 1.3) {
      return 'dual';
    }
    return 'single';
  }
}
