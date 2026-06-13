import MeasureText from '@ohos.measure';

/**
 * 单行文本：文本不超宽时居中显示，超宽时自动横向滚动（跑马灯），保证长标题完整可见。
 * 注意：MeasureText.measureText 返回的宽度单位是 px，而 onAreaChange 的容器宽度是 vp，
 * 必须换算到同一单位（vp）后再比较，否则中等长度文本会被误判为溢出而触发滚动。
 */
@Component
export struct AutoScrollText {
  @Prop @Watch('onContentChanged') text: string = '';
  @Prop fontSize: number = 14;
  @Prop fontWeight: FontWeight = FontWeight.Regular;
  @Prop fontColor: ResourceColor = '#000000';
  @Prop step: number = 6;
  @State private containerWidth: number = 0;
  @State private textWidth: number = 0;

  private onContentChanged(): void {
    this.measureTextWidth();
  }

  // 返回文本自然宽度的 vp 值（measureText 结果是 px，这里转成 vp）。
  private measureTextWidth(): void {
    if (this.text.length === 0) {
      this.textWidth = 0;
      return;
    }
    try {
      const widthPx = MeasureText.measureText({
        textContent: this.text,
        fontSize: this.fontSize,
        fontWeight: this.fontWeight
      });
      this.textWidth = this.getUIContext().px2vp(widthPx);
    } catch (error) {
      this.textWidth = 0;
    }
  }

  private shouldScroll(): boolean {
    return this.containerWidth > 0 && this.textWidth > this.containerWidth + 1;
  }

  build() {
    Stack() {
      if (this.shouldScroll()) {
        Marquee({
          start: true,
          step: this.step,
          loop: -1,
          fromStart: true,
          src: this.text
        })
          .fontSize(this.fontSize)
          .fontWeight(this.fontWeight)
          .fontColor(this.fontColor)
      } else {
        Text(this.text)
          .fontSize(this.fontSize)
          .fontWeight(this.fontWeight)
          .fontColor(this.fontColor)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .width('100%')
      }
    }
    .width('100%')
    .clip(true)
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      this.containerWidth = newValue.width as number;
      this.measureTextWidth();
    })
  }
}
