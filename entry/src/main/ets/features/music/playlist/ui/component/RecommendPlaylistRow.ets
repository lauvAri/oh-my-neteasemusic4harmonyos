import common from '@ohos.app.ability.common';
import { router } from '@kit.ArkUI';
import { RecommendPlaylist } from '../../domain/model/RecommendPlaylistModels';
import { RecommendPlaylistApi } from '../../data/api/RecommendPlaylistApi';

@Component
export struct RecommendPlaylistRow {
  @State private playlists: RecommendPlaylist[] = [];
  @State private loading: boolean = true;
  @State private errorMessage: string = '';

  private api?: RecommendPlaylistApi;

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    this.api = new RecommendPlaylistApi(context);
    this.loadPlaylists();
  }

  private async loadPlaylists(): Promise<void> {
    if (this.api === undefined) {
      return;
    }

    this.loading = true;
    this.errorMessage = '';

    try {
      const response = await this.api.getDailyRecommendResources();
      this.playlists = response.recommend;
    } catch (error) {
      const message = (error as Error).message;
      this.errorMessage = message.length > 0 ? message : '推荐歌单加载失败';
    } finally {
      this.loading = false;
    }
  }

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

  @Builder
  private playlistCard(playlist: RecommendPlaylist) {
    Column({ space: 6 }) {
      Stack({ alignContent: Alignment.BottomStart }) {
        Image(playlist.picUrl)
          .width(120)
          .height(120)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)

        Row() {
          if (playlist.copywriter.length > 0) {
            Text(playlist.copywriter)
              .fontSize(11)
              .fontColor(Color.White)
              .backgroundColor('#66000000')
              .padding({ left: 4, right: 4, top: 2, bottom: 2 })
              .borderRadius(4)
              .margin(6)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .constraintSize({ maxWidth: 80 })
          } else {
            Blank()
          }

          if (this.formatPlayCount(playlist.playcount).length > 0) {
            Text(this.formatPlayCount(playlist.playcount))
              .fontSize(11)
              .fontColor(Color.White)
              .backgroundColor('#66000000')
              .padding({ left: 4, right: 4, top: 2, bottom: 2 })
              .borderRadius(4)
              .margin(6)
          }
        }
        .width('100%')
      }
      .width(120)
      .height(120)

      Text(playlist.name)
        .fontSize(13)
        .fontColor('#1f2937')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
    }
    .width(120)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      router.pushUrl({
        url: 'pages/PlaylistDetailPage',
        params: {
          playlistId: playlist.id
        }
      });
    })
  }

  build() {
    Column({ space: 10 }) {
      Text('推荐歌单')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1f2937')
        .width('100%')

      if (this.loading) {
        Column({ space: 8 }) {
          LoadingProgress()
            .width(28)
            .height(28)
          Text('推荐歌单加载中...')
            .fontSize(13)
            .fontColor('#666666')
        }
        .width('100%')
        .height(140)
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMessage.length > 0) {
        Column({ space: 8 }) {
          Text(this.errorMessage)
            .fontSize(13)
            .fontColor('#d94841')
          Button('重试')
            .onClick(() => {
              this.loadPlaylists();
            })
        }
        .width('100%')
        .height(140)
        .justifyContent(FlexAlign.Center)
      } else if (this.playlists.length === 0) {
        Text('暂无推荐歌单')
          .fontSize(13)
          .fontColor('#666666')
          .width('100%')
          .height(140)
          .textAlign(TextAlign.Center)
      } else {
        Scroll() {
          Row({ space: 12 }) {
            ForEach(this.playlists, (item: RecommendPlaylist) => {
              this.playlistCard(item);
            }, (item: RecommendPlaylist) => `${item.id}`)
          }
          .padding({ left: 0, right: 4 })
        }
        .width('100%')
        .scrollable(ScrollDirection.Horizontal)
      }
    }
    .width('100%')
  }
}
