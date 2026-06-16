import common from '@ohos.app.ability.common';
import { promptAction } from '@kit.ArkUI';
import { HighqualityPlaylistApi } from '../features/music/playlist/data/api/HighqualityPlaylistApi';
import {
  HighqualityPlaylistItem,
  HighqualityPlaylistResponse,
  HighqualityPlaylistTagItem
} from '../features/music/playlist/domain/model/HighqualityPlaylistModels';
import { getSubpageBottomPaddingVp } from '../common/ui/PageLayout';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const PAGE_SIZE: number = 30;
const DEFAULT_TAG: string = '全部';

@Component
export struct HighqualityPlaylistsPage {
  @StorageLink('miniPlayerVisible') private miniPlayerVisible: boolean = false;
  @State private playlists: HighqualityPlaylistItem[] = [];
  @State private tags: HighqualityPlaylistTagItem[] = [];
  @State private selectedTag: string = DEFAULT_TAG;
  @State private hasMore: boolean = true;
  @State private nextBefore: number = 0;
  @State private isLoading: boolean = true;
  @State private tagsLoading: boolean = true;
  @State private loadingMore: boolean = false;
  @State private errorMessage: string = '';

  private api?: HighqualityPlaylistApi;
  @Consume('pathStack') pathStack: NavPathStack;

  aboutToAppear(): void {
    hilog.info(DOMAIN, 'NavRoute', 'HighqualityPlaylistsPage aboutToAppear');
    const context = getContext(this) as common.UIAbilityContext;
    this.api = new HighqualityPlaylistApi(context);
    void this.loadTags();
    void this.loadFirstPage(DEFAULT_TAG);
  }

  private async loadTags(): Promise<void> {
    if (this.api === undefined) {
      return;
    }
    this.tagsLoading = true;
    try {
      const response = await this.api.getHighqualityTags();
      this.tags = response.tags;
    } catch (error) {
      promptAction.showToast({ message: `歌单标签加载失败：${(error as Error).message}` });
    } finally {
      this.tagsLoading = false;
    }
  }

  private async loadFirstPage(tag: string): Promise<void> {
    if (this.api === undefined) {
      return;
    }
    this.selectedTag = tag;
    this.isLoading = true;
    this.errorMessage = '';
    this.playlists = [];
    this.hasMore = true;
    this.nextBefore = 0;
    try {
      const response = await this.api.getHighqualityPlaylists(tag, PAGE_SIZE, 0);
      this.applyFirstPage(response);
    } catch (error) {
      const message = (error as Error).message;
      this.errorMessage = message.length > 0 ? message : '精品歌单加载失败';
    } finally {
      this.isLoading = false;
    }
  }

  private async loadNextPage(): Promise<void> {
    if (this.api === undefined || !this.hasMore || this.loadingMore || this.isLoading) {
      return;
    }
    this.loadingMore = true;
    try {
      const response = await this.api.getHighqualityPlaylists(this.selectedTag, PAGE_SIZE, this.nextBefore);
      this.playlists = [...this.playlists, ...response.playlists];
      this.hasMore = response.more && response.playlists.length > 0;
      this.nextBefore = this.resolveNextBefore(response.playlists, response.lasttime);
    } catch (error) {
      const message = (error as Error).message;
      const errorText = message.length > 0 ? message : '加载更多失败';
      promptAction.showToast({ message: errorText });
    } finally {
      this.loadingMore = false;
    }
  }

  private applyFirstPage(response: HighqualityPlaylistResponse): void {
    this.playlists = response.playlists;
    this.hasMore = response.more && response.playlists.length > 0;
    this.nextBefore = this.resolveNextBefore(response.playlists, response.lasttime);
  }

  private resolveNextBefore(playlists: HighqualityPlaylistItem[], fallback: number): number {
    if (playlists.length === 0) {
      return fallback;
    }
    const last = playlists[playlists.length - 1];
    return last.updateTime > 0 ? last.updateTime : fallback;
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

  private getBottomPadding(): number {
    return getSubpageBottomPaddingVp(this.miniPlayerVisible);
  }

  private openPlaylist(playlistId: number): void {
    this.pathStack.pushPath({ name: 'PlaylistDetailPage', param: playlistId });
    AppStorage.setOrCreate<number>('mainNavDepth', this.pathStack.size());
  }

  @Builder
  private tagChip(tagName: string) {
    Button(tagName)
      .type(ButtonType.Normal)
      .height(32)
      .padding({ left: 14, right: 14 })
      .fontSize(13)
      .fontColor(this.selectedTag === tagName ? Color.White : $r('app.color.text_secondary'))
      .backgroundColor(this.selectedTag === tagName ? $r('app.color.text_brand') : $r('app.color.surface_subtle'))
      .borderRadius(16)
      .onClick(() => {
        if (this.selectedTag !== tagName) {
          void this.loadFirstPage(tagName);
        }
      })
  }

  @Builder
  private tagBar() {
    if (this.tagsLoading && this.tags.length === 0) {
      Row({ space: 8 }) {
        LoadingProgress()
          .width(16)
          .height(16)
        Text('标签加载中...')
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
      }
      .height(36)
      .width('100%')
    } else {
      Scroll() {
        Row({ space: 8 }) {
          this.tagChip(DEFAULT_TAG);
          ForEach(this.tags, (tag: HighqualityPlaylistTagItem) => {
            this.tagChip(tag.name);
          }, (tag: HighqualityPlaylistTagItem) => `${tag.id}`)
        }
        .padding({ right: 4 })
      }
      .width('100%')
      .height(36)
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
    }
  }

  @Builder
  private playlistRow(playlist: HighqualityPlaylistItem) {
    Row({ space: 12 }) {
      Image(playlist.coverImgUrl)
        .width(64)
        .height(64)
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

        Text(`${this.formatPlayCount(playlist.playCount)}播放 · ${playlist.trackCount}首`)
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
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
      this.openPlaylist(playlist.id);
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

        Text('精品歌单')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .alignSelf(ItemAlign.Center)
          .margin({ left: 12 })
      }
      .width('100%')

      this.tagBar();

      if (this.isLoading) {
        Column({ space: 12 }) {
          LoadingProgress()
            .width(28)
            .height(28)
          Text('正在获取精品歌单...')
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
              void this.loadFirstPage(this.selectedTag);
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .padding({ bottom: this.getBottomPadding() })
      } else if (this.playlists.length === 0) {
        Column() {
          Text('暂无精品歌单')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .padding({ bottom: this.getBottomPadding() })
      } else {
        List({ space: 2 }) {
          ForEach(this.playlists, (playlist: HighqualityPlaylistItem) => {
            ListItem() {
              this.playlistRow(playlist);
            }
          }, (playlist: HighqualityPlaylistItem) => `${playlist.id}`)
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
