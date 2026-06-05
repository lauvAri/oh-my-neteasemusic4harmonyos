import common from '@ohos.app.ability.common';
import { promptAction, router } from '@kit.ArkUI';
import { DailyRecommendApi } from '../features/music/data/api/DailyRecommendApi';
import { DailyRecommendSong } from '../features/music/domain/model/DailyRecommendModels';
import { PlayerEngine } from '../features/music/service/PlayerEngine';
import { DailyRecommendSongList } from '../features/music/ui/component/DailyRecommendSongList';
import { MiniPlayerBar } from '../features/music/ui/mini/MiniPlayerBar';

@Entry
@Component
struct DailyRecommendPage {
  @State private loading: boolean = true;
  @State private errorMessage: string = '';
  @State private songs: DailyRecommendSong[] = [];

  private api?: DailyRecommendApi;
  private engine: PlayerEngine = PlayerEngine.getInstance();

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    this.api = new DailyRecommendApi(context);
    this.loadSongs();
  }

  private async loadSongs(): Promise<void> {
    if (this.api === undefined) {
      return;
    }

    this.loading = true;
    this.errorMessage = '';

    try {
      const response = await this.api.getDailyRecommendSongs();
      this.songs = response.data.dailySongs;
    } catch (error) {
      const message = (error as Error).message;
      this.errorMessage = message.length > 0 ? message : '每日推荐歌曲加载失败';
    } finally {
      this.loading = false;
    }
  }

  private async playSong(song: DailyRecommendSong): Promise<void> {
    try {
      await this.engine.playSong(song.id);
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
    Column({ space: 14 }) {
      Row({ space: 12 }) {
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

        Column({ space: 2 }) {
          Text('每日推荐歌曲')
            .fontSize(24)
            .fontWeight(FontWeight.Medium)
          Text('为你更新的私人歌单')
            .fontSize(13)
            .fontColor('#666666')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      if (this.loading) {
        Column({ space: 12 }) {
          LoadingProgress()
            .width(44)
            .height(44)
          Text('正在获取每日推荐...')
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
              this.loadSongs();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        DailyRecommendSongList({
          songs: this.songs,
          callbacks: {
            onSongClick: (song: DailyRecommendSong): void => {
              void this.playSong(song);
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
