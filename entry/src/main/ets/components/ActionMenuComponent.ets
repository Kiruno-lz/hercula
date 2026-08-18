import { resolveRuntimeLayoutMetrics, RuntimeLayoutMetrics } from '../domain/ResponsiveLayout';
import { DEFAULT_THEME_ID, resolveTheme, ThemeId, ThemePalette } from '../domain/Theme';

const ACTION_MENU_OPEN_DURATION: number = 160;
const ACTION_MENU_CLOSE_DURATION: number = 180;
const ACTION_MENU_TEXT_DURATION: number = 160;
const ACTION_MENU_TEXT_DELAY: number = 120;
const DEFAULT_LAYOUT_METRICS: RuntimeLayoutMetrics = resolveRuntimeLayoutMetrics(1320, 2120);
const DEFAULT_THEME: ThemePalette = resolveTheme(DEFAULT_THEME_ID);

@Component
export struct ActionMenuComponent {
  @Prop actionMenuOpen: boolean = false;
  @Prop layoutMetrics: RuntimeLayoutMetrics = DEFAULT_LAYOUT_METRICS;
  @Prop theme: ThemePalette = DEFAULT_THEME;
  @Prop selectedThemeId: ThemeId = DEFAULT_THEME_ID;
  onOpenChange: (open: boolean) => void = (_open: boolean): void => {};
  onImport: () => void = (): void => {};
  onExport: () => void = (): void => {};
  onAbout: () => void = (): void => {};
  onThemeChange: (themeId: ThemeId) => void = (_themeId: ThemeId): void => {};

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
          Row({ space: 6 }) {
            this.buildThemeSwatch('rose')
            this.buildThemeSwatch('sage')
            this.buildThemeSwatch('coral')
            this.buildThemeSwatch('indigo')
          }
          .height(this.layoutMetrics.actionMenuThemeRowHeightVp)
          .justifyContent(FlexAlign.End)
          .opacity(this.actionMenuOpen ? 1 : 0)
          .translate({ x: this.actionMenuOpen ? 0 : 14 })
          .animation({
            duration: ACTION_MENU_TEXT_DURATION,
            curve: Curve.EaseOut,
            delay: this.actionMenuOpen ? ACTION_MENU_TEXT_DELAY : 0
          })
          Divider()
            .strokeWidth(1)
            .color(this.theme.divider)
            .width('100%')
          Button('导入日期')
            .fontSize(16)
            .fontColor(this.theme.text)
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
            .color(this.theme.divider)
            .width('100%')
          Button('导出日期')
            .fontSize(16)
            .fontColor(this.theme.text)
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
            .color(this.theme.divider)
            .width('100%')
          Button('关于软件')
            .fontSize(16)
            .fontColor(this.theme.text)
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
      .backgroundColor(this.theme.glassSurface)
      .backgroundBlurStyle(BlurStyle.Thin, { scale: 0.1 })
      .backgroundEffect({ radius: 24, saturation: 1.06, brightness: 1.03 })
      .border({ width: 1, color: this.theme.glassBorder })
      .borderRadius(this.actionMenuOpen ? 20 : 22)
      .shadow({ radius: 24, color: this.theme.glassShadow, offsetX: 0, offsetY: 10 })
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

  @Builder
  private buildThemeSwatch(themeId: ThemeId) {
    Button() {
      Circle()
        .width(this.layoutMetrics.actionMenuThemeSwatchSizeVp - 6)
        .height(this.layoutMetrics.actionMenuThemeSwatchSizeVp - 6)
        .fill(resolveTheme(themeId).swatch)
    }
    .width(this.layoutMetrics.actionMenuThemeSwatchSizeVp)
    .height(this.layoutMetrics.actionMenuThemeSwatchSizeVp)
    .padding(0)
    .backgroundColor('transparent')
    .border({
      width: this.selectedThemeId === themeId ? 2 : 1,
      color: this.selectedThemeId === themeId ? this.theme.accent : this.theme.glassBorder
    })
    .borderRadius(this.layoutMetrics.actionMenuThemeSwatchSizeVp / 2)
    .onClick((): void => {
      this.onThemeChange(themeId);
    })
  }
}
