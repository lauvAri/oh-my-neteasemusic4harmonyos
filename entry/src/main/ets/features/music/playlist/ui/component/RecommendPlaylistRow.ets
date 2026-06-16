import common from '@ohos.app.ability.common';
import { RecommendPlaylist } from '../../domain/model/RecommendPlaylistModels';
import { RecommendPlaylistApi } from '../../data/api/RecommendPlaylistApi';
import { HighqualityPlaylistApi } from '../../data/api/HighqualityPlaylistApi';
import { HighqualityPlaylistItem } from '../../domain/model/HighqualityPlaylistModels';
import { TwoLineTitle } from '../../../../../common/ui/TwoLineTitle';
import { SessionStore } from '../../../../../common/storage/SessionStore';

interface HomePlaylistCard {
  id: number;
  name: string;
  coverUrl: string;
  copywriter: string;
  playCount: number;
}

@Component
export struct RecommendPlaylistRow {
  @State private playlists: HomePlaylistCard[] = [];
  @State private isLoggedIn: boolean = false;
  @State private loading: boolean = true;
  @State private errorMessage: string = '';
  @Consume('pathStack') pathStack: NavPathStack;

  private recommendApi?: RecommendPlaylistApi;
  private highqualityApi?: HighqualityPlaylistApi;
  private sessionStore?: SessionStore;

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    this.recommendApi = new RecommendPlaylistApi(context);
    this.highqualityApi = new HighqualityPlaylistApi(context);
    this.sessionStore = new SessionStore(context);
    void this.loadPlaylists();
  }

  private async loadPlaylists(): Promise<void> {
    if (this.recommendApi === undefined || this.highqualityApi === undefined || this.sessionStore === undefined) {
      return;
    }

    this.loading = true;
    this.errorMessage = '';

    try {
      const cookie = await this.sessionStore.getCookie();
      this.isLoggedIn = cookie.length > 0;
      if (this.isLoggedIn) {
        const response = await this.recommendApi.getDailyRecommendResources();
        this.playlists = response.recommend.map((item: RecommendPlaylist): HomePlaylistCard => {
          return {
            id: item.id,
            name: item.name,
            coverUrl: item.picUrl,
            copywriter: item.copywriter,
            playCount: item.playcount
          };
        });
      } else {
        const response = await this.highqualityApi.getHighqualityPlaylists('全部', 12, 0);
        this.playlists = response.playlists.map((item: HighqualityPlaylistItem): HomePlaylistCard => {
          return {
            id: item.id,
            name: item.name,
            coverUrl: item.coverImgUrl,
            copywriter: item.copywriter,
            playCount: item.playCount
          };
        });
      }
    } catch (error) {
      const message = (error as Error).message;
      this.errorMessage = message.length > 0 ? message : `${this.getSectionTitle()}加载失败`;
    } finally {
      this.loading = false;
    }
  }

  private getSectionTitle(): string {
    return this.isLoggedIn ? '推荐歌单' : '精品歌单';
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
  private sectionTitle() {
    Row({ space: 8 }) {
      Text(this.getSectionTitle())
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)

      if (!this.isLoggedIn) {
        Text('全部')
          .fontSize(13)
          .fontColor($r('app.color.text_brand'))
      }
    }
    .width('100%')
    .onClick(() => {
      if (!this.isLoggedIn) {
        this.pathStack.pushPath({ name: 'HighqualityPlaylistsPage' });
        AppStorage.setOrCreate<number>('mainNavDepth', this.pathStack.size());
      }
    })
  }

  @Builder
  private playlistCard(playlist: HomePlaylistCard) {
    Column({ space: 6 }) {
      Stack({ alignContent: Alignment.BottomStart }) {
        Image(playlist.coverUrl)
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

          if (this.formatPlayCount(playlist.playCount).length > 0) {
            Text(this.formatPlayCount(playlist.playCount))
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

      TwoLineTitle({
        content: playlist.name,
        fontSize: 13,
        fontColor: $r('app.color.text_primary'),
        titleWidth: '100%'
      })
    }
    .width(120)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      this.pathStack.pushPath({
        name: 'PlaylistDetailPage',
        param: playlist.id
      });
      AppStorage.setOrCreate<number>('mainNavDepth', this.pathStack.size());
    })
  }

  build() {
    Column({ space: 10 }) {
      this.sectionTitle();

      if (this.loading) {
        Column({ space: 8 }) {
          LoadingProgress()
            .width(28)
            .height(28)
          Text(`${this.getSectionTitle()}加载中...`)
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .height(140)
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMessage.length > 0) {
        Column({ space: 8 }) {
          Text(this.errorMessage)
            .fontSize(13)
            .fontColor($r('app.color.text_danger'))
          Button('重试')
            .onClick(() => {
              this.loadPlaylists();
            })
        }
        .width('100%')
        .height(140)
        .justifyContent(FlexAlign.Center)
      } else if (this.playlists.length === 0) {
        Text(`暂无${this.getSectionTitle()}`)
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .height(140)
          .textAlign(TextAlign.Center)
      } else {
        Scroll() {
          Row({ space: 12 }) {
            ForEach(this.playlists, (item: HomePlaylistCard) => {
              this.playlistCard(item);
            }, (item: HomePlaylistCard) => `${item.id}`)
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
