@Component
export struct SearchSuggestList {
  @Prop keywords: string[] = [];
  @Prop loading: boolean = false;

  onItemClick: (searchWord: string) => void = () => {};

  @Builder
  private itemRow(keyword: string) {
    Row({ space: 12 }) {
      Image($r('app.media.ic_search'))
        .width(16)
        .height(16)
        .fillColor($r('app.color.icon_primary'))

      Text(keyword)
        .fontSize(15)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .onClick(() => {
      this.onItemClick(keyword);
    })
  }

  build() {
    if (this.loading && this.keywords.length === 0) {
      Column({ space: 8 }) {
        LoadingProgress()
          .width(28)
          .height(28)
        Text('联想中...')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else if (this.keywords.length === 0) {
      Text('暂无联想')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
    } else {
      List({ space: 0 }) {
        ForEach(this.keywords, (keyword: string) => {
          ListItem() {
            this.itemRow(keyword);
          }
        }, (keyword: string) => keyword)
      }
      .width('100%')
      .layoutWeight(1)
      .listDirection(Axis.Vertical)
      .divider({ strokeWidth: 0.5, color: $r('app.color.divider_subtle') })
    }
  }
}
