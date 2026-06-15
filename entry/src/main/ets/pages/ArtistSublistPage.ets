import common from '@ohos.app.ability.common';
import { promptAction } from '@kit.ArkUI';
import { ArtistSublistApi } from '../features/mine/data/api/ArtistSublistApi';
import { SubscribedArtistItem } from '../features/mine/domain/model/MineModels';
import { SUBPAGE_BOTTOM_PADDING_VP } from '../common/ui/PageLayout';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const PAGE_SIZE: number = 25;

@Component
export struct ArtistSublistPage {
  @State artists: SubscribedArtistItem[] = [];
  @State hasMore: boolean = true;
  @State nextOffset: number = 0;
  @State isLoading: boolean = true;
  @State loadingMore: boolean = false;
  @State errorMessage: string = '';

  private api?: ArtistSublistApi;
  @Consume('pathStack') pathStack: NavPathStack;

  aboutToAppear(): void {
    hilog.info(DOMAIN, 'NavRoute', 'ArtistSublistPage aboutToAppear');
    const context = getContext(this) as common.UIAbilityContext;
    this.api = new ArtistSublistApi(context);
    void this.loadFirstPage();
  }

  private async loadFirstPage(): Promise<void> {
    if (this.api === undefined) {
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const response = await this.api.getArtistSublist(PAGE_SIZE, 0);
      this.artists = response.data;
      this.nextOffset = response.data.length;
    } catch (error) {
      const message = (error as Error).message;
      this.errorMessage = message.length > 0 ? message : '收藏歌手加载失败';
    } finally {
      this.isLoading = false;
    }
  }

  private async loadNextPage(): Promise<void> {
    if (this.api === undefined) {
      return;
    }
    if (!this.hasMore || this.loadingMore || this.isLoading) {
      return;
    }
    this.loadingMore = true;
    try {
      const response = await this.api.getArtistSublist(PAGE_SIZE, this.nextOffset);
      this.artists = [...this.artists, ...response.data];
      this.nextOffset = this.nextOffset + response.data.length;
    } catch (error) {
      const message = (error as Error).message;
      this.errorMessage = message.length > 0 ? message : '加载更多失败';
      promptAction.showToast({ message: this.errorMessage });
    } finally {
      this.loadingMore = false;
    }
  }

  @Builder
  private artistRow(artist: SubscribedArtistItem) {
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

          if (artist.alias !== undefined && artist.alias.length > 0) {
            Text(artist.alias.join(' / '))
              .fontSize(12)
              .fontColor($r('app.color.text_tertiary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .width('100%')

        Text(`${artist.albumSize}专辑 · ${artist.mvSize ?? 0}MV`)
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
    .onClick(() => {
      this.pathStack.pushPath({ name: 'ArtistDetailPage', param: artist.id });
      AppStorage.setOrCreate<number>('mainNavDepth', this.pathStack.size());
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
          void this.loadNextPage();
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
    Column({ space: 14 }) {
      Row({ space: 12 }) {
        Button() {
          Image($r('app.media.ic_arrow_back'))
            .width(18)
            .height(18)
            .fillColor($r('app.color.icon_primary'))
        }
        .type(ButtonType.Circle)
        .width(36)
        .height(36)
        .backgroundColor($r('app.color.surface_subtle'))
        .onClick(() => {
          this.pathStack.pop();
          AppStorage.setOrCreate<number>('mainNavDepth', this.pathStack.size());
        })

        Text('收藏的歌手')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .alignSelf(ItemAlign.Center)
          .margin({ left: 12 })
      }
      .width('100%')

      if (this.isLoading) {
        Column({ space: 12 }) {
          LoadingProgress()
            .width(28)
            .height(28)
          Text('正在获取...')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMessage.length > 0 && this.artists.length === 0) {
        Column({ space: 12 }) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor($r('app.color.text_danger'))
          Button('重试')
            .onClick(() => {
              void this.loadFirstPage();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.artists.length === 0) {
        Column() {
          Text('暂无收藏歌手')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 2 }) {
          ForEach(this.artists, (artist: SubscribedArtistItem) => {
            ListItem() {
              this.artistRow(artist);
            }
          }, (artist: SubscribedArtistItem) => `${artist.id}`)
          ListItem() {
            this.footerArea();
          }
        }
        .width('100%')
        .layoutWeight(1)
        .listDirection(Axis.Vertical)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: SUBPAGE_BOTTOM_PADDING_VP })
  }
}
