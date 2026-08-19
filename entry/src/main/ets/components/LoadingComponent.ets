import { DEFAULT_THEME_ID, resolveTheme, ThemePalette } from '../domain/Theme';

const DEFAULT_THEME: ThemePalette = resolveTheme(DEFAULT_THEME_ID);

@Component
export struct LoadingComponent {
  @Prop theme: ThemePalette = DEFAULT_THEME;
  build() {
    Column({ space: 22 }) {
      Blank()
      Column({ space: 2 }) {
        Text('月迹')
          .fontSize(52)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.text)
        Text('hercula')
          .fontSize(18)
          .fontColor(this.theme.accent)
          .letterSpacing(2)
      }
      .alignItems(HorizontalAlign.Center)

      Row({ space: 24 }) {
        Circle()
          .width(18)
          .height(18)
          .fill(this.theme.loadingSecondary)
          .shadow({ radius: 8, color: this.theme.glassShadow, offsetX: 0, offsetY: 2 })
        Circle()
          .width(18)
          .height(18)
          .fill(this.theme.loadingPrimary)
          .shadow({ radius: 8, color: this.theme.glassShadow, offsetX: 0, offsetY: 2 })
        Circle()
          .width(18)
          .height(18)
          .fill(this.theme.loadingContrast)
          .shadow({ radius: 8, color: this.theme.glassShadow, offsetX: 0, offsetY: 2 })
      }

      Text('正在准备记录')
        .fontSize(20)
        .fontColor(this.theme.accent)
      Blank()
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
    .radialGradient({
      center: ['50%', '46%'],
      radius: '74%',
      colors: [[this.theme.pageBackgroundDeep, 0.0], [this.theme.pageBackground, 1.0]]
    })
  }
}
