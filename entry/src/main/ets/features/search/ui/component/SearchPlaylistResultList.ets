import { router } from '@kit.ArkUI';
import { SearchPlaylistItem } from '../../domain/model/SearchModels';

@Component
export struct SearchPlaylistResultList {
  @Prop playlists: SearchPlaylistItem[] = [];
  @Prop loadingMore: boolean = false;
  @Prop hasMore: boolean = false;
  @Prop isLoading: boolean = false;
  @Prop errorMessage: string = '';
  onLoadMore: () => void = () => {};

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
    router.pushUrl({
      url: 'pages/PlaylistDetailPage',
      params: {
        playlistId: item.id
      }
    });
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
          .fontColor('#1f2937')
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(item.creator.nickname)
          .fontSize(12)
          .fontColor('#666666')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${this.formatPlayCount(item.playCount)}播放 · ${item.trackCount}首`)
          .fontSize(11)
          .fontColor('#999999')
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
          .fontColor('#999999')
      }
      .width('100%')
      .height(48)
      .justifyContent(FlexAlign.Center)
    } else if (this.hasMore) {
      Button('加载更多')
        .width('100%')
        .height(40)
        .backgroundColor('#f2f3f5')
        .fontColor('#1677ff')
        .onClick(() => {
          this.onLoadMore();
        })
    } else {
      Text('没有更多了')
        .fontSize(12)
        .fontColor('#999999')
        .width('100%')
        .height(48)
        .textAlign(TextAlign.Center)
    }
  }

  build() {
    if (this.isLoading) {
      Column({ space: 8 }) {
        LoadingProgress()
          .width(28)
          .height(28)
        Text('搜索中...')
          .fontSize(13)
          .fontColor('#666666')
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else if (this.errorMessage.length > 0) {
      Column({ space: 8 }) {
        Text(this.errorMessage)
          .fontSize(13)
          .fontColor('#d94841')
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else if (this.playlists.length === 0) {
      Column() {
        Text('暂无搜索结果')
          .fontSize(13)
          .fontColor('#666666')
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
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
      }
      .width('100%')
      .layoutWeight(1)
      .listDirection(Axis.Vertical)
    }
  }
}
