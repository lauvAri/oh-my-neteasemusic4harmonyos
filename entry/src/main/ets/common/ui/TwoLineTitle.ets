@Component
export struct TwoLineTitle {
  @Prop content: string = '';
  @Prop fontSize: number = 12;
  @Prop fontColor: ResourceColor = $r('app.color.text_secondary');
  @Prop titleWidth: Length = '100%';
  @Prop lineHeight: number = 20;
  @Prop titleAlign: TextAlign = TextAlign.Start;
  @Prop maxLines: number = 2;
  @Prop overflow: TextOverflowOptions = { overflow: TextOverflow.Ellipsis };

  build() {
    Text(this.content)
      .fontSize(this.fontSize)
      .fontColor(this.fontColor)
      .lineHeight(this.lineHeight)
      .height(this.lineHeight * this.maxLines)
      .width(this.titleWidth)
      .maxLines(this.maxLines)
      .textAlign(this.titleAlign)
      .textOverflow(this.overflow)
  }
}
