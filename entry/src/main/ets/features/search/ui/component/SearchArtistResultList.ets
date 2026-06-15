import { SearchArtistItem } from '../../domain/model/SearchModels';
import { getSubpageBottomPaddingVp } from '../../../../common/ui/PageLayout';

@Component
export struct SearchArtistResultList {
  @StorageLink('miniPlayerVisible') private miniPlayerVisible: boolean = false;
  @Prop artists: SearchArtistItem[] = [];
  @Prop loadingMore: boolean = false;
  @Prop hasMore: boolean = false;
  @Prop isLoading: boolean = false;
  @Prop errorMessage: string = '';
  onLoadMore: () => void = () => {};

  @Builder
  private artistRow(artist: SearchArtistItem, index: number) {
    Row({ space: 12 }) {
      Image(artist.picUrl)
        .width(60)
        .height(60)
        .borderRadius(30)
        .objectFit(ImageFit.Cover)

      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Text(artist.name)
            .fontSize(15)
            .fontColor($r('app.color.text_primary'))
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (artist.alias && artist.alias.length > 0) {
            Text(artist.alias.join(' / '))
              .fontSize(12)
              .fontColor($r('app.color.text_tertiary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .width('100%')

        Text(`${artist.albumSize}专辑 · ${artist.musicSize}单曲`)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
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
    } else if (this.artists.length === 0) {
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
        ForEach(this.artists, (artist: SearchArtistItem, index: number) => {
          ListItem() {
            this.artistRow(artist, index);
          }
        }, (artist: SearchArtistItem) => `${artist.id}`)
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
