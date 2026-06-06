import common from '@ohos.app.ability.common';
import { promptAction, router } from '@kit.ArkUI';
import { PlaylistDetail, PlaylistDetailResponse } from '../features/music/playlist/domain/model/PlaylistDetailModels';
import { PlaylistDetailApi } from '../features/music/playlist/data/api/PlaylistDetailApi';
import { Song } from '../features/music/domain/model/Song';
import { SongList, SongListCallbacks } from '../features/music/ui/component/SongList';
import { PlayerEngine } from '../features/music/service/PlayerEngine';
import { MiniPlayerBar } from '../features/music/ui/mini/MiniPlayerBar';

@Entry
@Component
struct PlaylistDetailPage {
  @State private playlist: PlaylistDetail | null = null;
  @State private loading: boolean = true;
  @State private errorMessage: string = '';

  private api?: PlaylistDetailApi;
  private engine: PlayerEngine = PlayerEngine.getInstance();
  private readonly playlistId: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>;
    const rawId = params['playlistId'];
    let parsedId = 0;
    if (typeof rawId === 'number') {
      parsedId = rawId;
    } else if (typeof rawId === 'string') {
      const parsed = Number.parseInt(rawId, 10);
      if (!Number.isNaN(parsed)) {
        parsedId = parsed;
      }
    }

    if (parsedId <= 0) {
      this.loading = false;
      this.errorMessage = '歌单 ID 无效';
      return;
    }

    const context = getContext(this) as common.UIAbilityContext;
    this.api = new PlaylistDetailApi(context);
    this.loadDetail(parsedId);
  }

  private async loadDetail(playlistId: number): Promise<void> {
    if (this.api === undefined) {
      return;
    }

    this.loading = true;
    this.errorMessage = '';

    try {
      const response: PlaylistDetailResponse = await this.api.getPlaylistDetail(playlistId);
      this.playlist = response.playlist;
    } catch (error) {
      const message = (error as Error).message;
      this.errorMessage = message.length > 0 ? message : '歌单详情加载失败';
    } finally {
      this.loading = false;
    }
  }

  private formatCount(count: number): string {
    if (count >= 100000000) {
      const value = (count / 100000000).toFixed(1);
      return `${value}亿`;
    }
    if (count >= 10000) {
      const value = Math.floor(count / 10000);
      return `${value}万`;
    }
    return count > 0 ? `${count}` : '0';
  }

  private async playSong(song: Song, index: number): Promise<void> {
    if (this.playlist === null) {
      return;
    }
    try {
      await this.engine.setQueue(this.playlist.tracks, index);
      router.pushUrl({
        url: 'pages/MusicPlayerPage',
        params: {
          songId: song.id
        }
      });
    } catch (error) {
      promptAction.showToast({ message: '歌曲播放失败' });
    }
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Button() {
          Image($r('app.media.ic_arrow_back'))
            .width(18)
            .height(18)
        }
        .type(ButtonType.Circle)
        .width(36)
        .height(36)
        .backgroundColor('#eceff3')
        .onClick(() => {
          router.back();
        })

        Text('歌单详情')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .alignSelf(ItemAlign.Center)
          .margin({ left: 12 })
      }
      .width('100%')

      if (this.loading) {
        Column({ space: 12 }) {
          LoadingProgress()
            .width(44)
            .height(44)
          Text('正在加载歌单详情...')
            .fontSize(14)
            .fontColor('#666666')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMessage.length > 0) {
        Column({ space: 12 }) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#d94841')
          Button('重试')
            .onClick(() => {
              if (this.playlistId > 0) {
                this.loadDetail(this.playlistId);
              }
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.playlist === null) {
        Text('暂无歌单数据')
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      } else {
        Row({ space: 12 }) {
          Image(this.playlist.coverImgUrl)
            .width(100)
            .height(100)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)

          Column({ space: 4 }) {
            Text(this.playlist.name)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1f2937')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(this.playlist.creator.nickname)
              .fontSize(12)
              .fontColor('#666666')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(`${this.formatCount(this.playlist.playCount)}次播放 · ${this.formatCount(this.playlist.subscribedCount)}收藏`)
              .fontSize(11)
              .fontColor('#999999')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            if (this.playlist.tags !== null && this.playlist.tags.length > 0) {
              Text(this.playlist.tags.join(' / '))
                .fontSize(11)
                .fontColor('#999999')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')

        if (this.playlist.description !== null && this.playlist.description.length > 0) {
          Text(this.playlist.description)
            .fontSize(12)
            .fontColor('#666666')
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }

        Text(`共 ${this.playlist.trackCount} 首`)
          .fontSize(13)
          .fontColor('#666666')
          .width('100%')

        SongList({
          songs: this.playlist.tracks,
          callbacks: {
            onSongClick: (song: Song, index: number): void => {
              void this.playSong(song, index);
            }
          }
        })
      }

      MiniPlayerBar();
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 8 })
  }
}
