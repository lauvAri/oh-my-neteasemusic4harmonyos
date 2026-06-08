@Component
export struct GlassSurface {
  @Prop blurStyle: BlurStyle = BlurStyle.Regular;
  @Prop radius: number = 20;
  @Prop enableHighlight: boolean = true;
  @Prop contentPadding: Padding | Length = { left: 12, right: 12, top: 8, bottom: 8 };
  @Prop contentSpacing: number = 8;

  @BuilderParam content: () => void = this.defaultContent;

  @Builder
  defaultContent() {
  }

  build() {
    Column({ space: this.contentSpacing }) {
      Column() {
        this.content();
      }
      .width('100%')
    }
    .width('100%')
    .padding(this.contentPadding)
    .linearGradient({
      angle: 180,
      colors: [
        [$r('app.color.glass_highlight_light'), 0.0],
        [$r('app.color.glass_tint_light'), 0.5],
        [$r('app.color.glass_tint_light'), 1.0]
      ]
    })
    .backgroundBlurStyle(this.blurStyle, {
      colorMode: ThemeColorMode.SYSTEM,
      adaptiveColor: AdaptiveColor.AVERAGE,
      scale: 1.0
    })
    .borderRadius(this.radius)
    .clip(true)
    .border({
      width: this.enableHighlight ? 1 : 0,
      color: $r('app.color.glass_border_light')
    })
  }
}
