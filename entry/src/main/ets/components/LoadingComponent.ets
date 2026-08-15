const PINK_BACKGROUND: string = '#F8F2F3';
const PERIOD_COLOR: string = '#C98291';
const ACCENT_COLOR: string = '#A95E70';
const TEXT_COLOR: string = '#594B50';

@Component
export struct LoadingComponent {
  build() {
    Column({ space: 22 }) {
      Blank()
      Column({ space: 2 }) {
        Text('月迹')
          .fontSize(52)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_COLOR)
        Text('hercula')
          .fontSize(18)
          .fontColor(ACCENT_COLOR)
          .letterSpacing(2)
      }
      .alignItems(HorizontalAlign.Center)

      Row({ space: 24 }) {
        Circle()
          .width(18)
          .height(18)
          .fill('#E7C6CD')
          .shadow({ radius: 8, color: '#6FC98291', offsetX: 0, offsetY: 2 })
        Circle()
          .width(18)
          .height(18)
          .fill(PERIOD_COLOR)
          .shadow({ radius: 8, color: '#8FC98291', offsetX: 0, offsetY: 2 })
        Circle()
          .width(18)
          .height(18)
          .fill('#D5DEE7')
          .shadow({ radius: 8, color: '#6F9DB3CC', offsetX: 0, offsetY: 2 })
      }

      Text('正在准备记录')
        .fontSize(20)
        .fontColor(ACCENT_COLOR)
      Blank()
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
    .radialGradient({
      center: ['50%', '46%'],
      radius: '74%',
      colors: [['#F1DDE1', 0.0], [PINK_BACKGROUND, 1.0]]
    })
  }
}
