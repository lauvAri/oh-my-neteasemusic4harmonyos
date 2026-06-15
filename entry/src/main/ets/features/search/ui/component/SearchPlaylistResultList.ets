import { SearchPlaylistItem } from '../../domain/model/SearchModels';
import { getSubpageBottomPaddingVp } from '../../../../common/ui/PageLayout';

@Component
export struct SearchPlaylistResultList {
  @StorageLink('miniPlayerVisible') private miniPlayerVisible: boolean = false;
  @Prop playlists: SearchPlaylistItem[] = [];
  @Prop loadingMore: boolean = false;
  @Prop hasMore: boolean = false;
  @Prop isLoading: boolean = false;
  @Prop errorMessage: string = '';
  onLoadMore: () => void = () => {};
  @Consume('pathStack') pathStack: NavPathStack;

  private formatPlayCount(count: number): string {
    if (count >= 100000000) {
      const value = (count / 100000000).toFixed(1);
      return `${value}亿`;
    }
    if (count >= 10000) {
      const value = Math.floor(count / 10000);
      return `${value}万`;
    }
    return count > 0 ? `${count}` : '';
  }

  private handleItemClick(item: SearchPlaylistItem): void {
    this.pathStack.pushPath({
      name: 'PlaylistDetailPage',
      param: item.id
    });
    AppStorage.setOrCreate<number>('mainNavDepth', this.pathStack.size());
  }

  @Builder
  private playlistRow(item: SearchPlaylistItem, index: number) {
    Row({ space: 12 }) {
      Image(item.coverImgUrl)
        .width(60)
        .height(60)
        .borderRadius(6)
        .objectFit(ImageFit.Cover)

      Column({ space: 4 }) {
        Text(item.name)
          .fontSize(15)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(item.creator.nickname)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${this.formatPlayCount(item.playCount)}播放 · ${item.trackCount}首`)
          .fontSize(11)
          .fontColor($r('app.color.text_tertiary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .onClick(() => {
      this.handleItemClick(item);
    })
  }

  @Builder
  private footerArea() {
    if (this.loadingMore) {
      Row({ space: 8 }) {
        LoadingProgress()
          .width(16)
          .height(16)
        Text('加载中...')
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
      }
      .width('100%')
      .height(48)
      .justifyContent(FlexAlign.Center)
    } else if (this.hasMore) {
      Button('加载更多')
        .width('100%')
        .height(40)
        .backgroundColor($r('app.color.surface_input'))
        .fontColor($r('app.color.text_brand'))
        .onClick(() => {
          this.onLoadMore();
        })
    } else {
      Text('没有更多了')
        .fontSize(12)
        .fontColor($r('app.color.text_tertiary'))
        .width('100%')
        .height(48)
        .textAlign(TextAlign.Center)
    }
  }

  private getBottomPadding(): number {
    return getSubpageBottomPaddingVp(this.miniPlayerVisible);
  }

  build() {
    if (this.isLoading) {
      Column({ space: 8 }) {
        LoadingProgress()
          .width(28)
          .height(28)
        Text('搜索中...')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .padding({ bottom: this.getBottomPadding() })
    } else if (this.errorMessage.length > 0) {
      Column({ space: 8 }) {
        Text(this.errorMessage)
          .fontSize(13)
          .fontColor($r('app.color.text_danger'))
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .padding({ bottom: this.getBottomPadding() })
    } else if (this.playlists.length === 0) {
      Column() {
        Text('暂无搜索结果')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .padding({ bottom: this.getBottomPadding() })
    } else {
      List({ space: 2 }) {
        ForEach(this.playlists, (item: SearchPlaylistItem, index: number) => {
          ListItem() {
            this.playlistRow(item, index);
          }
        }, (item: SearchPlaylistItem) => `${item.id}`)
        ListItem() {
          this.footerArea();
        }
        ListItem() {
          Row() {
            Blank().height(this.getBottomPadding());
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
      .listDirection(Axis.Vertical)
    }
  }
}
