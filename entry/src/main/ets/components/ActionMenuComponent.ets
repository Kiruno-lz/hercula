import { resolveRuntimeLayoutMetrics, RuntimeLayoutMetrics } from '../domain/ResponsiveLayout';

const TEXT_COLOR: string = '#594B50';
const ACTION_MENU_OPEN_DURATION: number = 160;
const ACTION_MENU_CLOSE_DURATION: number = 180;
const ACTION_MENU_TEXT_DURATION: number = 160;
const ACTION_MENU_TEXT_DELAY: number = 120;
const DEFAULT_LAYOUT_METRICS: RuntimeLayoutMetrics = resolveRuntimeLayoutMetrics(1320, 2120);

@Component
export struct ActionMenuComponent {
  @Prop actionMenuOpen: boolean = false;
  @Prop layoutMetrics: RuntimeLayoutMetrics = DEFAULT_LAYOUT_METRICS;
  onOpenChange: (open: boolean) => void = (_open: boolean): void => {};
  onImport: () => void = (): void => {};
  onExport: () => void = (): void => {};
  onAbout: () => void = (): void => {};

  build() {
    Stack() {
      Stack() {
        Button() {
          Image($r('app.media.action_menu'))
            .width(this.layoutMetrics.actionMenuIconSizeVp)
            .height(this.layoutMetrics.actionMenuIconSizeVp)
        }
        .backgroundColor('transparent')
        .borderRadius(22)
        .width(this.layoutMetrics.actionMenuCollapsedSizeVp)
        .height(this.layoutMetrics.actionMenuCollapsedSizeVp)
        .padding(0)
        .opacity(this.actionMenuOpen ? 0 : 1)
        .translate({ x: this.actionMenuOpen ? -40 : 0 })
        .blur(this.actionMenuOpen ? 2 : 0)
        .enabled(!this.actionMenuOpen)
        .onClick((): void => {
          this.onOpenChange(true);
        })

        Column({ space: 0 }) {
          Button('导入日期')
            .fontSize(16)
            .fontColor(TEXT_COLOR)
            .backgroundColor('transparent')
            .height(this.layoutMetrics.actionMenuItemHeightVp)
            .width('100%')
            .padding(0)
            .opacity(this.actionMenuOpen ? 1 : 0)
            .translate({ x: this.actionMenuOpen ? 0 : 14 })
            .blur(this.actionMenuOpen ? 0 : 2)
            .animation({
              duration: ACTION_MENU_TEXT_DURATION,
              curve: Curve.EaseOut,
              delay: this.actionMenuOpen ? ACTION_MENU_TEXT_DELAY : 0
            })
            .onClick((): void => {
              this.onOpenChange(false);
              this.onImport();
            })
          Divider()
            .strokeWidth(1)
            .color('#28FFFFFF')
            .width('100%')
          Button('导出日期')
            .fontSize(16)
            .fontColor(TEXT_COLOR)
            .backgroundColor('transparent')
            .height(this.layoutMetrics.actionMenuItemHeightVp)
            .width('100%')
            .padding(0)
            .opacity(this.actionMenuOpen ? 1 : 0)
            .translate({ x: this.actionMenuOpen ? 0 : 14 })
            .blur(this.actionMenuOpen ? 0 : 2)
            .animation({
              duration: ACTION_MENU_TEXT_DURATION,
              curve: Curve.EaseOut,
              delay: this.actionMenuOpen ? ACTION_MENU_TEXT_DELAY : 0
            })
            .onClick((): void => {
              this.onOpenChange(false);
              this.onExport();
            })
          Divider()
            .strokeWidth(1)
            .color('#28FFFFFF')
            .width('100%')
          Button('关于软件')
            .fontSize(16)
            .fontColor(TEXT_COLOR)
            .backgroundColor('transparent')
            .height(this.layoutMetrics.actionMenuItemHeightVp)
            .width('100%')
            .padding(0)
            .opacity(this.actionMenuOpen ? 1 : 0)
            .translate({ x: this.actionMenuOpen ? 0 : 14 })
            .blur(this.actionMenuOpen ? 0 : 2)
            .animation({
              duration: ACTION_MENU_TEXT_DURATION,
              curve: Curve.EaseOut,
              delay: this.actionMenuOpen ? ACTION_MENU_TEXT_DELAY : 0
            })
            .onClick((): void => {
              this.onOpenChange(false);
              this.onAbout();
            })
        }
        .padding({
          left: this.layoutMetrics.actionMenuHorizontalPaddingVp,
          right: this.layoutMetrics.actionMenuHorizontalPaddingVp,
          top: this.layoutMetrics.actionMenuVerticalPaddingVp,
          bottom: this.layoutMetrics.actionMenuVerticalPaddingVp
        })
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
        .height('100%')
        .opacity(this.actionMenuOpen ? 1 : 0)
        .translate({ x: this.actionMenuOpen ? 0 : 40 })
        .blur(this.actionMenuOpen ? 0 : 2)
        .enabled(this.actionMenuOpen)
      }
      .position({
        x: this.actionMenuOpen ? 0 : this.layoutMetrics.actionMenuCollapsedAnchorOffsetVp,
        y: this.actionMenuOpen ? this.layoutMetrics.actionMenuExpandedAnchorOffsetYVp : 0
      })
      .width(this.actionMenuOpen
        ? this.layoutMetrics.actionMenuExpandedWidthVp
        : this.layoutMetrics.actionMenuCollapsedSizeVp)
      .height(this.actionMenuOpen
        ? this.layoutMetrics.actionMenuExpandedHeightVp
        : this.layoutMetrics.actionMenuCollapsedSizeVp)
      .backgroundColor('#E9FFF9FA')
      .backgroundBlurStyle(BlurStyle.Thin, { scale: 0.1 })
      .backgroundEffect({ radius: 24, saturation: 1.06, brightness: 1.03 })
      .border({ width: 1, color: '#B8FFFFFF' })
      .borderRadius(this.actionMenuOpen ? 20 : 22)
      .shadow({ radius: 24, color: '#3A9B7280', offsetX: 0, offsetY: 10 })
      .zIndex(3)
      .animation({
        duration: this.actionMenuOpen
          ? ACTION_MENU_OPEN_DURATION
          : ACTION_MENU_CLOSE_DURATION,
        curve: this.actionMenuOpen ? Curve.EaseOut : Curve.EaseInOut
      })
    }
    .width(this.layoutMetrics.actionMenuExpandedWidthVp)
    .height(this.layoutMetrics.actionMenuCollapsedSizeVp)
  }
}
