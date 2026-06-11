import common from '@ohos.app.ability.common';
import { promptAction, router } from '@kit.ArkUI';
import { AuthService, UserAccountResponse } from '../features/auth/service/AuthService';
import { UserPlaylistApi } from '../features/mine/data/api/UserPlaylistApi';
import { AlbumSublistApi } from '../features/mine/data/api/AlbumSublistApi';
import { ArtistSublistApi } from '../features/mine/data/api/ArtistSublistApi';
import { UserPlaylistItem, SubscribedAlbumItem, SubscribedArtistItem } from
  '../features/mine/domain/model/MineModels';
import { TAB_PAGE_BOTTOM_PADDING_VP } from '../common/ui/PageLayout';
import { TwoLineTitle } from '../common/ui/TwoLineTitle';

@Component
export struct MinePage {
  @Consume('pathStack') pathStack: NavPathStack;

  @State loading: boolean = false;
  @State loaded: boolean = false;
  @State errorText: string = '';
  @State nickname: string = '';
  @State avatarUrl: string = '';
  @State backgroundUrl: string = '';
  @State signature: string = '';
  @State userId: number = 0;
  @State userName: string = '';
  @State accountName: string = '';
  @State profileVipType: number = 0;
  @State accountVipType: number = 0;

  @State likedPlaylistId: number = 0;
  @State likedTrackCount: number = 0;
  @State playlists: UserPlaylistItem[] = [];
  @State subscribedAlbums: SubscribedAlbumItem[] = [];
  @State subscribedArtists: SubscribedArtistItem[] = [];
  @State contentLoading: boolean = false;

  private authService?: AuthService;
  private userPlaylistApi?: UserPlaylistApi;
  private albumSublistApi?: AlbumSublistApi;
  private artistSublistApi?: ArtistSublistApi;

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    this.authService = new AuthService(context);
    this.userPlaylistApi = new UserPlaylistApi(context);
    this.albumSublistApi = new AlbumSublistApi(context);
    this.artistSublistApi = new ArtistSublistApi(context);
    this.loadAccountInfo();
  }

  private async loadAccountInfo(): Promise<void> {
    if (this.authService === undefined || this.loading) {
      return;
    }

    this.loading = true;
    this.errorText = '';

    try {
      const cookie = await this.authService.getCookie();
      if (cookie.length === 0) {
        this.loaded = false;
        this.errorText = '未登录，请先完成二维码登录';
        return;
      }

      const response: UserAccountResponse = await this.authService.getAccountInfo();
      this.nickname = response.profile.nickname;
      this.avatarUrl = response.profile.avatarUrl;
      this.backgroundUrl = response.profile.backgroundUrl;
      this.signature = response.profile.signature === undefined ? '' : response.profile.signature;
      this.userId = response.profile.userId;
      this.userName = response.profile.userName;
      this.accountName = response.account.userName;
      this.profileVipType = response.profile.vipType;
      this.accountVipType = response.account.vipType;
      this.loaded = true;
      this.loadMyContent();
    } catch (error) {
      const errMsg = (error as Error).message ?? '';
      if (errMsg.includes('301') || errMsg.includes('cookie') || errMsg.includes('登录')) {
        await this.authService.clearCookie();
      }
      this.loaded = false;
      this.errorText = `账号信息获取失败：${errMsg}`;
      promptAction.showToast({ message: '账号信息获取失败' });
    } finally {
      this.loading = false;
    }
  }

  private async loadMyContent(): Promise<void> {
    if (this.userId === 0) {
      return;
    }
    this.contentLoading = true;
    try {
      const results = await Promise.allSettled([
        this.userPlaylistApi?.getUserPlaylist(this.userId) ?? Promise.reject(new Error('未初始化')),
        this.albumSublistApi?.getAlbumSublist() ?? Promise.reject(new Error('未初始化')),
        this.artistSublistApi?.getArtistSublist() ?? Promise.reject(new Error('未初始化'))
      ]);

      if (results[0].status === 'fulfilled') {
        const playlistResp = results[0].value;
        if (playlistResp.playlist.length > 0) {
          this.likedPlaylistId = playlistResp.playlist[0].id;
          this.likedTrackCount = playlistResp.playlist[0].trackCount;
        }
        this.playlists = playlistResp.playlist.slice(1);
      }
      if (results[1].status === 'fulfilled') {
        this.subscribedAlbums = results[1].value.data;
      }
      if (results[2].status === 'fulfilled') {
        this.subscribedArtists = results[2].value.data;
      }
    } catch (error) {
      console.error(`加载我的内容失败: ${(error as Error).message}`);
    } finally {
      this.contentLoading = false;
    }
  }

  private async logout(): Promise<void> {
    await this.authService?.clearCookie();
    promptAction.showToast({ message: '已退出登录' });
    router.replaceUrl({ url: 'pages/Index' });
  }

  @Builder
  private infoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.text_quaternary'))
        .width(88)
      Text(value)
        .fontSize(15)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
  }

  @Builder
  private sectionHeader(title: string) {
    Text(title)
      .fontSize(17)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.text_primary'))
      .width('100%')
      .margin({ top: 4 })
  }

  @Builder
  private likedMusicCard() {
    Row({ space: 12 }) {
      Stack() {
        Column()
          .width(56)
          .height(56)
          .borderRadius(8)
          .backgroundColor($r('app.color.surface_brand_tint'))
        Text('♥')
          .fontSize(24)
          .fontColor($r('app.color.text_brand'))
      }

      Column({ space: 4 }) {
        Text('我喜欢的音乐')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Text(`${this.likedTrackCount} 首`)
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($r('app.media.ic_arrow_back'))
        .width(16)
        .height(16)
        .fillColor($r('app.color.text_tertiary'))
        .rotate({ angle: 180 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.surface_info'))
    .borderRadius(10)
    .onClick(() => {
      if (this.likedPlaylistId > 0) {
        this.pathStack.pushPath({ name: 'PlaylistDetailPage', param: this.likedPlaylistId });
        AppStorage.setOrCreate<number>('mainNavDepth', this.pathStack.size());
      }
    })
  }

  @Builder
  private playlistGrid() {
    Scroll() {
      Row({ space: 12 }) {
        ForEach(this.playlists, (item: UserPlaylistItem) => {
          Column({ space: 6 }) {
            Image(item.coverImgUrl)
              .width(100)
              .height(100)
              .borderRadius(8)
              .objectFit(ImageFit.Cover)
            TwoLineTitle({
              content: item.name,
              fontSize: 12,
              fontColor: $r('app.color.text_secondary'),
              titleWidth: 100
            })
          }
          .onClick(() => {
            this.pathStack.pushPath({ name: 'PlaylistDetailPage', param: item.id });
            AppStorage.setOrCreate<number>('mainNavDepth', this.pathStack.size());
          })
        }, (item: UserPlaylistItem) => `${item.id}`)
      }
    }
    .width('100%')
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
  }

  @Builder
  private albumGrid() {
    Scroll() {
      Row({ space: 12 }) {
        ForEach(this.subscribedAlbums, (item: SubscribedAlbumItem) => {
          Column({ space: 6 }) {
            Image(item.picUrl)
              .width(100)
              .height(100)
              .borderRadius(8)
              .objectFit(ImageFit.Cover)
            TwoLineTitle({
              content: item.name,
              fontSize: 12,
              fontColor: $r('app.color.text_secondary'),
              titleWidth: 100
            })
            TwoLineTitle({
              content: item.artist ? item.artist.name : '',
              fontSize: 11,
              fontColor: $r('app.color.text_quaternary'),
              titleWidth: 100
            })
          }
          .onClick(() => {
            this.pathStack.pushPath({ name: 'AlbumDetailPage', param: item.id });
            AppStorage.setOrCreate<number>('mainNavDepth', this.pathStack.size());
          })
        }, (item: SubscribedAlbumItem) => `${item.id}`)
      }
    }
    .width('100%')
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
  }

  @Builder
  private artistGrid() {
    Scroll() {
      Row({ space: 12 }) {
        ForEach(this.subscribedArtists, (item: SubscribedArtistItem) => {
          Column({ space: 6 }) {
            Image(item.picUrl)
              .width(80)
              .height(80)
              .borderRadius(40)
              .objectFit(ImageFit.Cover)
            TwoLineTitle({
              content: item.name,
              fontSize: 12,
              fontColor: $r('app.color.text_secondary'),
              titleWidth: 80,
              titleAlign: TextAlign.Center
            })
          }
          .onClick(() => {
            this.pathStack.pushPath({ name: 'ArtistDetailPage', param: item.id });
            AppStorage.setOrCreate<number>('mainNavDepth', this.pathStack.size());
          })
        }, (item: SubscribedArtistItem) => `${item.id}`)
      }
    }
    .width('100%')
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('我的')
          .fontSize(26)
          .fontWeight(FontWeight.Medium)
          .width('100%')

        if (this.loading && !this.loaded) {
          Column({ space: 12 }) {
            LoadingProgress()
              .width(44)
              .height(44)
            Text('正在获取账号信息...')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .height(220)
          .justifyContent(FlexAlign.Center)
        } else if (this.loaded) {
          Column({ space: 16 }) {
            Stack({ alignContent: Alignment.BottomStart }) {
              if (this.backgroundUrl.length > 0) {
                Image(this.backgroundUrl)
                  .width('100%')
                  .height(150)
                  .objectFit(ImageFit.Cover)
              } else {
                Blank()
                  .width('100%')
                  .height(150)
                  .backgroundColor($r('app.color.surface_banner_fallback'))
              }

              Row({ space: 12 }) {
                Image(this.avatarUrl)
                  .width(72)
                  .height(72)
                  .objectFit(ImageFit.Cover)
                  .border({ width: 2, color: $r('app.color.text_on_dark_primary'), radius: 36 })

                Column({ space: 4 }) {
                  Text(this.nickname)
                    .fontSize(22)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_on_dark_primary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(this.signature.length > 0 ? this.signature : '这个人很懒，什么都没写')
                    .fontSize(13)
                    .fontColor($r('app.color.text_on_dark_secondary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .layoutWeight(1)
              }
              .width('100%')
              .padding(14)
              .linearGradient({
                angle: 0,
                colors: [['rgba(0,0,0,0.62)', 0], ['rgba(0,0,0,0)', 1]]
              })
            }
            .width('100%')
            .height(150)
            .borderRadius(8)
            .clip(true)

            Column({ space: 12 }) {
              this.infoRow('用户 ID', `${this.userId}`);
              this.infoRow('用户名', this.userName.length > 0 ? this.userName : this.accountName);
              this.infoRow('账号 VIP', `${this.accountVipType}`);
              this.infoRow('资料 VIP', `${this.profileVipType}`);
            }
            .width('100%')
            .padding(14)
            .backgroundColor($r('app.color.surface_info'))
            .borderRadius(8)

            if (this.contentLoading) {
              Row({ space: 8 }) {
                LoadingProgress()
                  .width(20)
                  .height(20)
                Text('正在加载...')
                  .fontSize(13)
                  .fontColor($r('app.color.text_secondary'))
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .padding(20)
            } else {
              if (this.likedPlaylistId > 0) {
                this.likedMusicCard();
              }

              if (this.playlists.length > 0) {
                Column({ space: 10 }) {
                  this.sectionHeader(`我的歌单 (${this.playlists.length})`);
                  this.playlistGrid();
                }
              }

              if (this.subscribedAlbums.length > 0) {
                Column({ space: 10 }) {
                  this.sectionHeader(`收藏的专辑 (${this.subscribedAlbums.length})`);
                  this.albumGrid();
                }
              }

              if (this.subscribedArtists.length > 0) {
                Column({ space: 10 }) {
                  this.sectionHeader(`关注的歌手 (${this.subscribedArtists.length})`);
                  this.artistGrid();
                }
              }
            }

            Row({ space: 10 }) {
              Button('刷新信息')
                .layoutWeight(1)
                .onClick(() => {
                  this.loadAccountInfo();
                })
              Button('退出登录')
                .layoutWeight(1)
                .fontColor($r('app.color.text_danger_strong'))
                .backgroundColor($r('app.color.surface_danger_subtle'))
                .onClick(() => {
                  this.logout();
                })
            }
            .width('100%')
          }
          .width('100%')
        } else {
          Column({ space: 12 }) {
            Text(this.errorText)
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .textAlign(TextAlign.Center)
            Button('返回登录')
              .onClick(() => {
                router.replaceUrl({ url: 'pages/Index' });
              })
          }
          .width('100%')
          .height(220)
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: TAB_PAGE_BOTTOM_PADDING_VP })
    }
    .width('100%')
    .height('100%')
  }
}
