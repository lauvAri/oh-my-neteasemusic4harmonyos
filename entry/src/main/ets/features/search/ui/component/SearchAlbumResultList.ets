import { SearchAlbumItem } from '../../domain/model/SearchModels';

@Component
export struct SearchAlbumResultList {
  @Prop albums: SearchAlbumItem[] = [];
  @Prop loadingMore: boolean = false;
  @Prop hasMore: boolean = false;
  @Prop isLoading: boolean = false;
  @Prop errorMessage: string = '';
  onLoadMore: () => void = () => {};

  private formatYear(ts: number): string {
    if (ts <= 0) {
      return '';
    }
    const date = new Date(ts);
    return `${date.getFullYear()}`;
  }

  private getArtistName(album: SearchAlbumItem): string {
    if (album.artist && album.artist.name) {
      return album.artist.name;
    }
    if (album.artists && album.artists.length > 0 && album.artists[0].name) {
      return album.artists[0].name;
    }
    return '未知艺术家';
  }

  @Builder
  private albumRow(album: SearchAlbumItem, index: number) {
    Row({ space: 12 }) {
      Image(album.picUrl)
        .width(60)
        .height(60)
        .borderRadius(6)
        .objectFit(ImageFit.Cover)

      Column({ space: 4 }) {
        Text(album.name)
          .fontSize(15)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.getArtistName(album))
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${this.formatYear(album.publishTime)} · ${album.size}首`)
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
    } else if (this.errorMessage.length > 0) {
      Column({ space: 8 }) {
        Text(this.errorMessage)
          .fontSize(13)
          .fontColor($r('app.color.text_danger'))
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else if (this.albums.length === 0) {
      Column() {
        Text('暂无搜索结果')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else {
      List({ space: 2 }) {
        ForEach(this.albums, (album: SearchAlbumItem, index: number) => {
          ListItem() {
            this.albumRow(album, index);
          }
        }, (album: SearchAlbumItem) => `${album.id}`)
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
