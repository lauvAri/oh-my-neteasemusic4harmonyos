import { MeasureText } from '@kit.ArkUI';

const ELLIPSIS: string = '...';
const EXPAND_LABEL: string = '展开';
const COLLAPSE_LABEL: string = '收起';

@Component
export struct ExpandableText {
  @Prop @Watch('onContentChanged') content: string = '';
  @Prop maxLines: number = 3;
  @Prop fontSize: number = 14;
  @Prop fontColor: ResourceColor = $r('app.color.text_secondary');
  @Prop brandColor: ResourceColor = $r('app.color.text_brand');
  @Prop constraintWidth: number = 0;

  @State private expanded: boolean = false;
  @State private needExpand: boolean = false;
  @State private collapsedText: string = '';

  aboutToAppear(): void {
    this.computeLayout();
  }

  private onContentChanged(): void {
    this.expanded = false;
    this.computeLayout();
  }

  private computeLayout(): void {
    if (this.content.length === 0) {
      this.needExpand = false;
      return;
    }

    const width = this.constraintWidth > 0 ? this.constraintWidth : 320;
    const suffix: string = ELLIPSIS + EXPAND_LABEL;

    const fullSize: SizeOptions = MeasureText.measureTextSize({
      textContent: this.content,
      fontSize: this.fontSize,
      constraintWidth: width,
    });

    const collapsedSize: SizeOptions = MeasureText.measureTextSize({
      textContent: this.content,
      fontSize: this.fontSize,
      constraintWidth: width,
      maxLines: this.maxLines,
    });

    const fullHeight: number = Number(fullSize.height) || 0;
    const collapsedHeight: number = Number(collapsedSize.height) || 0;

    if (fullHeight <= collapsedHeight) {
      this.needExpand = false;
      this.collapsedText = this.content;
      return;
    }

    this.needExpand = true;
    this.collapsedText = this.truncateText(width, collapsedHeight);
  }

  private truncateText(width: number, maxHeight: number): string {
    let left: number = 0;
    let right: number = this.content.length;
    const suffix: string = ELLIPSIS + EXPAND_LABEL;

    while (left <= right) {
      const mid: number = Math.floor((left + right) / 2);
      const testText: string = this.content.substring(0, mid) + suffix;

      const testSize: SizeOptions = MeasureText.measureTextSize({
        textContent: testText,
        fontSize: this.fontSize,
        constraintWidth: width,
      });

      if (Number(testSize.height) <= maxHeight) {
        left = mid + 1;
      } else {
        right = mid - 1;
      }
    }

    return this.content.substring(0, Math.max(0, right)) + ELLIPSIS;
  }

  build() {
    Column() {
      if (this.content.length === 0) {
        Blank()
      } else if (!this.needExpand) {
        Text(this.content)
          .fontSize(this.fontSize)
          .fontColor(this.fontColor)
          .width('100%')
      } else if (this.expanded) {
        Text(this.content)
          .fontSize(this.fontSize)
          .fontColor(this.fontColor)
          .width('100%')

        Text(COLLAPSE_LABEL)
          .fontSize(this.fontSize)
          .fontColor(this.brandColor)
          .margin({ top: 4 })
          .onClick(() => {
            this.expanded = false;
          })
      } else {
        Text() {
          Span(this.collapsedText)
            .fontSize(this.fontSize)
            .fontColor(this.fontColor)
          Span(EXPAND_LABEL)
            .fontSize(this.fontSize)
            .fontColor(this.brandColor)
        }
        .width('100%')
        .onClick(() => {
          this.expanded = true;
        })
      }
    }
    .width('100%')
  }
}
