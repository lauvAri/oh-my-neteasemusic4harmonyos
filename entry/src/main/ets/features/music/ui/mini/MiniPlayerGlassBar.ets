import { MiniPlayerBar } from './MiniPlayerBar';

@Component
export struct MiniPlayerGlassBar {
  @BuilderParam content: () => void = this.defaultContent;

  @Builder
  defaultContent() {
    MiniPlayerBar();
  }

  build() {
    Column() {
      this.content();
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .linearGradient({
      angle: 180,
      colors: [
        [$r('app.color.glass_highlight_light'), 0.0],
        [$r('app.color.glass_tint_light'), 0.5],
        [$r('app.color.glass_tint_light'), 1.0]
      ]
    })
    .backgroundBlurStyle(BlurStyle.Regular, {
      colorMode: ThemeColorMode.SYSTEM,
      adaptiveColor: AdaptiveColor.AVERAGE,
      scale: 1.0
    })
    .borderRadius(22)
    .clip(true)
    .border({
      width: 1,
      color: $r('app.color.glass_border_light')
    })
  }
}
