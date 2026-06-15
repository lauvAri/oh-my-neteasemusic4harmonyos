import common from '@ohos.app.ability.common';
import { promptAction, router } from '@kit.ArkUI';
import { DailyRecommendApi } from '../features/music/data/api/DailyRecommendApi';
import { Song } from '../features/music/domain/model/Song';
import { PlayerEngine } from '../features/music/service/PlayerEngine';
import { SongList } from '../features/music/ui/component/SongList';
import { getSubpageBottomPaddingVp } from '../common/ui/PageLayout';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;

@Component
export struct DailyRecommendPage {
  @StorageLink('miniPlayerVisible') private miniPlayerVisible: boolean = false;
  @State private loading: boolean = true;
  @State private errorMessage: string = '';
  @State private songs: Song[] = [];

  private api?: DailyRecommendApi;
  private engine: PlayerEngine = PlayerEngine.getInstance();
  @Consume('pathStack') pathStack: NavPathStack;

  aboutToAppear(): void {
    hilog.info(DOMAIN, 'NavRoute', 'DailyRecommendPage aboutToAppear');
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

  private async playSong(song: Song, index: number): Promise<void> {
    try {
      await this.engine.setQueue(this.songs, index);
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

  private getBottomPadding(): number {
    return getSubpageBottomPaddingVp(this.miniPlayerVisible);
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

        Column({ space: 2 }) {
          Text('每日推荐歌曲')
            .fontSize(24)
            .fontWeight(FontWeight.Medium)
          Text('为你更新的私人歌单')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
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
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .padding({ bottom: this.getBottomPadding() })
      } else if (this.errorMessage.length > 0) {
        Column({ space: 12 }) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor($r('app.color.text_danger'))
          Button('重试')
            .onClick(() => {
              this.loadSongs();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .padding({ bottom: this.getBottomPadding() })
      } else {
        Column() {
          SongList({
            songs: this.songs,
            callbacks: {
              onSongClick: (song: Song, index: number): void => {
                void this.playSong(song, index);
              }
            }
          })
          Blank().height(this.getBottomPadding())
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .padding({ left: 16, right: 16, top: 16 })
  }
}
