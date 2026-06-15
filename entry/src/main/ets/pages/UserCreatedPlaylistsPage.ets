import common from '@ohos.app.ability.common';
import { promptAction } from '@kit.ArkUI';
import { UserPlaylistApi } from '../features/mine/data/api/UserPlaylistApi';
import { PlaylistTagItem, UserPlaylistItem } from '../features/mine/domain/model/MineModels';
import { PlaylistDetailApi } from '../features/music/playlist/data/api/PlaylistDetailApi';
import { PlaylistDetailResponse } from '../features/music/playlist/domain/model/PlaylistDetailModels';
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
  @State likedPlaylistId: number = 0;
  @State showManageSheet: boolean = false;
  @State selectedPlaylist: UserPlaylistItem | null = null;
  @State editName: string = '';
  @State editDesc: string = '';
  @State editTags: string[] = [];
  @State playlistTags: PlaylistTagItem[] = [];
  @State tagsLoading: boolean = false;
  @State detailLoading: boolean = false;
  @State updatePending: boolean = false;
  @State deletePending: boolean = false;

  private api?: UserPlaylistApi;
  private detailApi?: PlaylistDetailApi;
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
    this.likedPlaylistId = AppStorage.get<number>('likedPlaylistId') ?? 0;
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
    this.likedPlaylistId = AppStorage.get<number>('likedPlaylistId') ?? 0;
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

  private isProtectedPlaylist(playlist: UserPlaylistItem): boolean {
    return playlist.id === this.likedPlaylistId || playlist.name === '我喜欢的音乐';
  }

  private openManageSheet(playlist: UserPlaylistItem): void {
    if (this.isProtectedPlaylist(playlist)) {
      promptAction.showToast({ message: '我喜欢的音乐不能删除或更新' });
      return;
    }
    this.selectedPlaylist = playlist;
    this.editName = playlist.name;
    this.editDesc = '';
    this.editTags = [];
    this.showManageSheet = true;
    void this.loadPlaylistForEdit(playlist.id);
    void this.loadPlaylistTags();
  }

  private closeManageSheet(): void {
    if (this.updatePending || this.deletePending) {
      return;
    }
    this.showManageSheet = false;
  }

  private async loadPlaylistForEdit(playlistId: number): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;
    if (this.detailApi === undefined) {
      this.detailApi = new PlaylistDetailApi(context);
    }
    this.detailLoading = true;
    try {
      const response: PlaylistDetailResponse = await this.detailApi.getPlaylistDetail(playlistId);
      if (this.selectedPlaylist !== null && this.selectedPlaylist.id === playlistId) {
        this.editName = response.playlist.name;
        this.editDesc = response.playlist.description ?? '';
        this.editTags = response.playlist.tags ?? [];
      }
    } catch (error) {
      promptAction.showToast({ message: `歌单信息加载失败：${(error as Error).message}` });
    } finally {
      this.detailLoading = false;
    }
  }

  private async loadPlaylistTags(): Promise<void> {
    if (this.api === undefined || this.tagsLoading || this.playlistTags.length > 0) {
      return;
    }
    this.tagsLoading = true;
    try {
      const response = await this.api.getPlaylistTags();
      this.playlistTags = response.tags;
    } catch (error) {
      promptAction.showToast({ message: `标签加载失败：${(error as Error).message}` });
    } finally {
      this.tagsLoading = false;
    }
  }

  private isTagSelected(tagName: string): boolean {
    return this.editTags.indexOf(tagName) >= 0;
  }

  private toggleTag(tagName: string): void {
    if (this.isTagSelected(tagName)) {
      this.editTags = this.editTags.filter((item: string) => item !== tagName);
      return;
    }
    if (this.editTags.length >= 3) {
      promptAction.showToast({ message: '最多选择 3 个标签' });
      return;
    }
    this.editTags = [...this.editTags, tagName];
  }

  private async updateSelectedPlaylist(): Promise<void> {
    if (this.api === undefined || this.selectedPlaylist === null || this.updatePending) {
      return;
    }
    if (this.isProtectedPlaylist(this.selectedPlaylist)) {
      promptAction.showToast({ message: '我喜欢的音乐不能删除或更新' });
      return;
    }
    const name = this.editName.trim();
    const desc = this.editDesc.trim();
    if (name.length === 0) {
      promptAction.showToast({ message: '请输入歌单名称' });
      return;
    }
    if (desc.length > 100) {
      promptAction.showToast({ message: '歌单描述不能超过 100 字' });
      return;
    }
    this.updatePending = true;
    try {
      await this.api.updatePlaylist({
        id: this.selectedPlaylist.id,
        name,
        desc,
        tags: this.editTags
      });
      const targetId = this.selectedPlaylist.id;
      this.playlists = this.playlists.map((item: UserPlaylistItem) => {
        if (item.id !== targetId) {
          return item;
        }
        return {
          id: item.id,
          name,
          coverImgUrl: item.coverImgUrl,
          trackCount: item.trackCount,
          playCount: item.playCount,
          creator: item.creator
        };
      });
      promptAction.showToast({ message: '歌单已更新' });
      this.showManageSheet = false;
    } catch (error) {
      promptAction.showToast({ message: `更新失败：${(error as Error).message}` });
    } finally {
      this.updatePending = false;
    }
  }

  private confirmDeleteSelectedPlaylist(): void {
    if (this.selectedPlaylist === null) {
      return;
    }
    if (this.isProtectedPlaylist(this.selectedPlaylist)) {
      promptAction.showToast({ message: '我喜欢的音乐不能删除或更新' });
      return;
    }
    const playlistName = this.selectedPlaylist.name;
    AlertDialog.show({
      title: '删除歌单',
      message: `确认删除「${playlistName}」？删除后不可恢复。`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: $r('app.color.text_danger'),
        action: () => {
          void this.deleteSelectedPlaylist();
        }
      }
    });
  }

  private async deleteSelectedPlaylist(): Promise<void> {
    if (this.api === undefined || this.selectedPlaylist === null || this.deletePending) {
      return;
    }
    if (this.isProtectedPlaylist(this.selectedPlaylist)) {
      promptAction.showToast({ message: '我喜欢的音乐不能删除或更新' });
      return;
    }
    const targetId = this.selectedPlaylist.id;
    this.deletePending = true;
    try {
      await this.api.deletePlaylist(targetId);
      this.playlists = this.playlists.filter((item: UserPlaylistItem) => item.id !== targetId);
      this.nextOffset = Math.max(0, this.nextOffset - 1);
      promptAction.showToast({ message: '歌单已删除' });
      this.showManageSheet = false;
    } catch (error) {
      promptAction.showToast({ message: `删除失败：${(error as Error).message}` });
    } finally {
      this.deletePending = false;
    }
  }

  @Builder
  private playlistRow(playlist: UserPlaylistItem) {
    Row({ space: 12 }) {
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
      .layoutWeight(1)
      .onClick(() => {
        this.pathStack.pushPath({ name: 'PlaylistDetailPage', param: playlist.id });
        AppStorage.setOrCreate<number>('mainNavDepth', this.pathStack.size());
      })

      if (this.isProtectedPlaylist(playlist)) {
        Text('受保护')
          .fontSize(11)
          .fontColor($r('app.color.text_tertiary'))
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor($r('app.color.surface_input'))
          .borderRadius(12)
      } else {
        Button('管理')
          .height(32)
          .fontSize(12)
          .fontColor($r('app.color.text_brand'))
          .backgroundColor($r('app.color.surface_brand_tint'))
          .borderRadius(16)
          .padding({ left: 12, right: 12 })
          .onClick(() => {
            this.openManageSheet(playlist);
          })
      }
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
    .bindSheet(this.showManageSheet, this.manageSheet(), {
      height: '82%',
      showClose: false,
      dragBar: true,
      onDisappear: () => {
        this.showManageSheet = false;
      }
    })
  }

  @Builder
  private selectedTagsPreview() {
    if (this.editTags.length === 0) {
      Text('未选择标签')
        .fontSize(12)
        .fontColor($r('app.color.text_tertiary'))
    } else {
      Text(this.editTags.join(' / '))
        .fontSize(12)
        .fontColor($r('app.color.text_brand'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
  }

  @Builder
  private tagChip(tag: PlaylistTagItem) {
    Text(tag.name)
      .fontSize(12)
      .fontColor(this.isTagSelected(tag.name) ? $r('app.color.text_on_dark_primary') : $r('app.color.text_secondary'))
      .padding({ left: 12, right: 12, top: 7, bottom: 7 })
      .backgroundColor(this.isTagSelected(tag.name) ? $r('app.color.text_brand') : $r('app.color.surface_input'))
      .borderRadius(16)
      .margin({ right: 8, bottom: 8 })
      .onClick(() => {
        this.toggleTag(tag.name);
      })
  }

  @Builder
  private manageSheet() {
    Column({ space: 14 }) {
      Row() {
        Text('管理歌单')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)

        Button('关闭')
          .height(34)
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .backgroundColor($r('app.color.surface_input'))
          .borderRadius(17)
          .onClick(() => {
            this.closeManageSheet();
          })
      }
      .width('100%')

      if (this.detailLoading) {
        Row({ space: 8 }) {
          LoadingProgress()
            .width(16)
            .height(16)
          Text('正在读取歌单信息...')
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
        }
        .width('100%')
      }

      Column({ space: 8 }) {
        Text('歌单名称')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')

        TextInput({ text: this.editName, placeholder: '输入歌单名称' })
          .height(44)
          .fontSize(15)
          .backgroundColor($r('app.color.surface_input'))
          .borderRadius(14)
          .onChange((value: string) => {
            this.editName = value;
          })
      }
      .width('100%')

      Column({ space: 8 }) {
        Row() {
          Text('歌单描述')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .layoutWeight(1)
          Text(`${this.editDesc.length}/100`)
            .fontSize(12)
            .fontColor(this.editDesc.length > 100 ? $r('app.color.text_danger') : $r('app.color.text_tertiary'))
        }
        .width('100%')

        TextArea({ text: this.editDesc, placeholder: '写一段 100 字以内的简介' })
          .height(92)
          .fontSize(14)
          .backgroundColor($r('app.color.surface_input'))
          .borderRadius(14)
          .onChange((value: string) => {
            this.editDesc = value;
          })
      }
      .width('100%')

      Column({ space: 8 }) {
        Row() {
          Text('官方标签')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .layoutWeight(1)
          this.selectedTagsPreview();
        }
        .width('100%')

        if (this.tagsLoading) {
          Row({ space: 8 }) {
            LoadingProgress()
              .width(16)
              .height(16)
            Text('标签加载中...')
              .fontSize(12)
              .fontColor($r('app.color.text_tertiary'))
          }
          .height(40)
        } else {
          Scroll() {
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(this.playlistTags, (tag: PlaylistTagItem) => {
                this.tagChip(tag);
              }, (tag: PlaylistTagItem) => `${tag.id}`)
            }
            .width('100%')
          }
          .height(128)
        }
      }
      .width('100%')

      Button(this.updatePending ? '保存中...' : '保存更新')
        .width('100%')
        .height(46)
        .fontSize(15)
        .fontColor($r('app.color.text_on_dark_primary'))
        .backgroundColor($r('app.color.text_brand'))
        .borderRadius(23)
        .enabled(!this.updatePending && !this.deletePending)
        .onClick(() => {
          void this.updateSelectedPlaylist();
        })

      Button(this.deletePending ? '删除中...' : '删除这个歌单')
        .width('100%')
        .height(44)
        .fontSize(14)
        .fontColor($r('app.color.text_danger'))
        .backgroundColor($r('app.color.surface_danger_subtle'))
        .borderRadius(22)
        .enabled(!this.updatePending && !this.deletePending)
        .onClick(() => {
          this.confirmDeleteSelectedPlaylist();
        })

      Text('我喜欢的音乐为系统歌单，不会显示更新或删除入口。')
        .fontSize(12)
        .fontColor($r('app.color.text_tertiary'))
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: this.getBottomPadding() + 16 })
  }
}
