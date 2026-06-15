import common from '@ohos.app.ability.common';
import { promptAction } from '@kit.ArkUI';
import { UserPlaylistApi } from '../features/mine/data/api/UserPlaylistApi';
import { UserPlaylistItem } from '../features/mine/domain/model/MineModels';
import { getSubpageBottomPaddingVp } from '../common/ui/PageLayout';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const PAGE_SIZE: number = 30;

@Component
export struct UserCreatedPlaylistsPage {
  @StorageLink('miniPlayerVisible') private miniPlayerVisible: boolean = false;
  @State playlists: UserPlaylistItem[] = [];
  @State hasMore: boolean = true;
  @State nextOffset: number = 0;
  @State isLoading: boolean = true;
  @State loadingMore: boolean = false;
  @State errorMessage: string = '';
  @State userId: number = 0;

  private api?: UserPlaylistApi;
  @Consume('pathStack') pathStack: NavPathStack;

  aboutToAppear(): void {
    hilog.info(DOMAIN, 'NavRoute', 'UserCreatedPlaylistsPage aboutToAppear');
    const context = getContext(this) as common.UIAbilityContext;
    this.api = new UserPlaylistApi(context);
    const storedUserId = AppStorage.get<number>('userId') ?? 0;
    if (storedUserId === 0) {
      this.isLoading = false;
      this.errorMessage = '未登录';
      return;
    }
    this.userId = storedUserId;
    void this.loadFirstPage();
  }

  private async loadFirstPage(): Promise<void> {
    if (this.api === undefined) {
      return;
    }
    const storedUserId = AppStorage.get<number>('userId') ?? 0;
    if (storedUserId === 0) {
      this.isLoading = false;
      this.errorMessage = '未登录';
      return;
    }
    this.userId = storedUserId;
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const response = await this.api.getUserCreatedPlaylists(this.userId, PAGE_SIZE, 0);
      this.playlists = response.data.playlist;
      this.nextOffset = response.data.playlist.length;
      this.hasMore = response.data.more;
    } catch (error) {
      const message = (error as Error).message;
      this.errorMessage = message.length > 0 ? message : '创建歌单加载失败';
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
      const response = await this.api.getUserCreatedPlaylists(this.userId, PAGE_SIZE, this.nextOffset);
      this.playlists = [...this.playlists, ...response.data.playlist];
      this.nextOffset = this.nextOffset + response.data.playlist.length;
      this.hasMore = response.data.more && response.data.playlist.length >= PAGE_SIZE;
    } catch (error) {
      const message = (error as Error).message;
      this.errorMessage = message.length > 0 ? message : '加载更多失败';
      promptAction.showToast({ message: this.errorMessage });
    } finally {
      this.loadingMore = false;
    }
  }

  @Builder
  private playlistRow(playlist: UserPlaylistItem) {
    Row({ space: 12 }) {
      Image(playlist.coverImgUrl)
        .width(60)
        .height(60)
        .borderRadius(8)
        .objectFit(ImageFit.Cover)

      Column({ space: 4 }) {
        Text(playlist.name)
          .fontSize(15)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(playlist.creator.nickname)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(`${playlist.trackCount} 首`)
          .fontSize(12)
          .fontColor($r('app.color.text_quaternary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .onClick(() => {
      this.pathStack.pushPath({ name: 'PlaylistDetailPage', param: playlist.id });
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

        Text('创建的歌单')
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
        .padding({ bottom: this.getBottomPadding() })
      } else if (this.errorMessage.length > 0 && this.playlists.length === 0) {
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
        .padding({ bottom: this.getBottomPadding() })
      } else if (this.playlists.length === 0) {
        Column() {
          Text('暂无创建的歌单')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .padding({ bottom: this.getBottomPadding() })
      } else {
        List({ space: 2 }) {
          ForEach(this.playlists, (playlist: UserPlaylistItem) => {
            ListItem() {
              this.playlistRow(playlist);
            }
          }, (playlist: UserPlaylistItem) => `${playlist.id}`)
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
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .padding({ left: 16, right: 16, top: 16 })
  }
}
