import { promptAction } from '@kit.ArkUI';
import common from '@ohos.app.ability.common';
import { HotSearchList } from '../features/search/ui/component/HotSearchList';
import { SearchSuggestList } from '../features/search/ui/component/SearchSuggestList';
import { SearchTabBar } from '../features/search/ui/component/SearchTabBar';
import { SearchSongResultList } from '../features/search/ui/component/SearchSongResultList';
import { SearchAlbumResultList } from '../features/search/ui/component/SearchAlbumResultList';
import { SearchArtistResultList } from '../features/search/ui/component/SearchArtistResultList';
import { SearchPlaylistResultList } from '../features/search/ui/component/SearchPlaylistResultList';
import { SearchApi } from '../features/search/data/api/SearchApi';
import { SUBPAGE_BOTTOM_PADDING_VP } from '../common/ui/PageLayout';
import {
  SearchType,
  SearchSongItem,
  SearchAlbumItem,
  SearchArtistItem,
  SearchPlaylistItem,
  SearchSuggestResult,
  SearchSuggestNameItem
} from '../features/search/domain/model/SearchModels';
import { mapSearchSongToSong } from '../features/search/domain/SearchSongMapper';
import { Song } from '../features/music/domain/model/Song';
import { Debouncer } from '../common/util/Debouncer';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;

const PAGE_SIZE: number = 30;

@Component
export struct SearchPage {
  @State private keyword: string = '';
  @State private submittedKeyword: string = '';
  @State private activeTab: SearchType = 'song';

  @State private songs: Song[] = [];
  @State private albums: SearchAlbumItem[] = [];
  @State private artists: SearchArtistItem[] = [];
  @State private playlists: SearchPlaylistItem[] = [];

  @State private songHasMore: boolean = true;
  @State private albumHasMore: boolean = true;
  @State private artistHasMore: boolean = true;
  @State private playlistHasMore: boolean = true;

  @State private songOffset: number = 0;
  @State private albumOffset: number = 0;
  @State private artistOffset: number = 0;
  @State private playlistOffset: number = 0;

  @State private songLoading: boolean = false;
  @State private albumLoading: boolean = false;
  @State private artistLoading: boolean = false;
  @State private playlistLoading: boolean = false;

  @State private songIsLoading: boolean = false;
  @State private albumIsLoading: boolean = false;
  @State private artistIsLoading: boolean = false;
  @State private playlistIsLoading: boolean = false;

  @State private songError: string = '';
  @State private albumError: string = '';
  @State private artistError: string = '';
  @State private playlistError: string = '';

  @State private suggestKeywords: string[] = [];
  @State private suggestLoading: boolean = false;

  private api?: SearchApi;
  private suggestDebouncer: Debouncer = new Debouncer(300);
  private suggestRequestId: number = 0;
  @Consume('pathStack') pathStack: NavPathStack;

  aboutToAppear(): void {
    hilog.info(DOMAIN, 'NavRoute', 'SearchPage aboutToAppear');
    const context = getContext(this) as common.UIAbilityContext;
    this.api = new SearchApi(context);
  }

  private submitWithKeyword(raw: string): void {
    const word = raw.trim();
    if (word.length === 0) {
      promptAction.showToast({ message: '请输入搜索关键词' });
      return;
    }

    this.suggestDebouncer.cancel();
    this.suggestKeywords = [];
    this.suggestLoading = false;

    this.keyword = word;
    this.submittedKeyword = word;
    this.activeTab = 'song';

    this.songs = [];
    this.albums = [];
    this.artists = [];
    this.playlists = [];

    this.songHasMore = true;
    this.albumHasMore = true;
    this.artistHasMore = true;
    this.playlistHasMore = true;

    this.songOffset = 0;
    this.albumOffset = 0;
    this.artistOffset = 0;
    this.playlistOffset = 0;

    this.songError = '';
    this.albumError = '';
    this.artistError = '';
    this.playlistError = '';

    this.fetchActiveTabFirstPage();
  }

  private scheduleSuggest(value: string): void {
    const word = value.trim();
    if (word.length === 0) {
      this.suggestDebouncer.cancel();
      this.suggestKeywords = [];
      this.suggestLoading = false;
      return;
    }
    this.suggestDebouncer.schedule(() => {
      this.fetchSuggest(word);
    });
  }

  private async fetchSuggest(word: string): Promise<void> {
    if (this.api === undefined) {
      return;
    }
    const requestId = ++this.suggestRequestId;
    this.suggestLoading = true;
    try {
      const response = await this.api.searchSuggest(word);
      // 丢弃过期响应，避免竞态时把旧联想词刷到界面上
      if (requestId !== this.suggestRequestId) {
        return;
      }
      this.suggestKeywords = this.extractSuggestKeywords(response.result);
    } catch (error) {
      if (requestId === this.suggestRequestId) {
        this.suggestKeywords = [];
      }
    } finally {
      if (requestId === this.suggestRequestId) {
        this.suggestLoading = false;
      }
    }
  }

  // 后端 /search/suggest 返回多类型结果（songs/artists/albums），而非关键词列表。
  // 这里按 songs → artists → albums 顺序提取名称、去重、截断为联想词条。
  private extractSuggestKeywords(result: SearchSuggestResult | undefined): string[] {
    if (result === undefined) {
      return [];
    }
    const merged: SearchSuggestNameItem[] = [
      ...(result.songs ?? []),
      ...(result.artists ?? []),
      ...(result.albums ?? [])
    ];
    const seen = new Set<string>();
    const out: string[] = [];
    for (const item of merged) {
      const name = (item.name ?? '').trim();
      if (name.length === 0 || seen.has(name)) {
        continue;
      }
      seen.add(name);
      out.push(name);
      if (out.length >= 10) {
        break;
      }
    }
    return out;
  }

  private onTabChange(newTab: SearchType): void {
    if (this.activeTab === newTab) {
      return;
    }
    this.activeTab = newTab;
    if (this.submittedKeyword.length === 0) {
      return;
    }
    if (this.hasResultsForTab(newTab)) {
      return;
    }
    this.fetchActiveTabFirstPage();
  }

  private hasResultsForTab(tab: SearchType): boolean {
    switch (tab) {
      case 'song': return this.songs.length > 0;
      case 'album': return this.albums.length > 0;
      case 'artist': return this.artists.length > 0;
      case 'playlist': return this.playlists.length > 0;
    }
  }

  private fetchActiveTabFirstPage(): void {
    if (this.submittedKeyword.length === 0) {
      return;
    }
    switch (this.activeTab) {
      case 'song': this.fetchSongs(0, true); break;
      case 'album': this.fetchAlbums(0, true); break;
      case 'artist': this.fetchArtists(0, true); break;
      case 'playlist': this.fetchPlaylists(0, true); break;
    }
  }

  private onLoadMore(): void {
    if (this.submittedKeyword.length === 0) {
      return;
    }
    switch (this.activeTab) {
      case 'song':
        if (!this.songHasMore || this.songLoading) return;
        this.fetchSongs(this.songOffset + PAGE_SIZE, false);
        break;
      case 'album':
        if (!this.albumHasMore || this.albumLoading) return;
        this.fetchAlbums(this.albumOffset + PAGE_SIZE, false);
        break;
      case 'artist':
        if (!this.artistHasMore || this.artistLoading) return;
        this.fetchArtists(this.artistOffset + PAGE_SIZE, false);
        break;
      case 'playlist':
        if (!this.playlistHasMore || this.playlistLoading) return;
        this.fetchPlaylists(this.playlistOffset + PAGE_SIZE, false);
        break;
    }
  }

  private async fetchSongs(offset: number, isFirst: boolean): Promise<void> {
    if (this.api === undefined) return;
    if (isFirst) {
      this.songIsLoading = true;
    } else {
      this.songLoading = true;
    }
    this.songError = '';
    try {
      const response = await this.api.searchSongs(this.submittedKeyword, offset, PAGE_SIZE);
      const items: SearchSongItem[] = response.result?.songs ?? [];
      const mapped: Song[] = items.map(mapSearchSongToSong);
      this.songs = isFirst ? mapped : [...this.songs, ...mapped];
      this.songOffset = offset;
      this.songHasMore = response.result?.hasMore ?? false;
    } catch (error) {
      const message = (error as Error).message;
      this.songError = message.length > 0 ? message : '搜索失败';
    } finally {
      this.songIsLoading = false;
      this.songLoading = false;
    }
  }

  private async fetchAlbums(offset: number, isFirst: boolean): Promise<void> {
    if (this.api === undefined) return;
    if (isFirst) {
      this.albumIsLoading = true;
    } else {
      this.albumLoading = true;
    }
    this.albumError = '';
    try {
      const response = await this.api.searchAlbums(this.submittedKeyword, offset, PAGE_SIZE);
      const items: SearchAlbumItem[] = response.result?.albums ?? [];
      this.albums = isFirst ? items : [...this.albums, ...items];
      this.albumOffset = offset;
      this.albumHasMore = items.length >= PAGE_SIZE;
    } catch (error) {
      const message = (error as Error).message;
      this.albumError = message.length > 0 ? message : '搜索失败';
    } finally {
      this.albumIsLoading = false;
      this.albumLoading = false;
    }
  }

  private async fetchArtists(offset: number, isFirst: boolean): Promise<void> {
    if (this.api === undefined) return;
    if (isFirst) {
      this.artistIsLoading = true;
    } else {
      this.artistLoading = true;
    }
    this.artistError = '';
    try {
      const response = await this.api.searchArtists(this.submittedKeyword, offset, PAGE_SIZE);
      const items: SearchArtistItem[] = response.result?.artists ?? [];
      this.artists = isFirst ? items : [...this.artists, ...items];
      this.artistOffset = offset;
      this.artistHasMore = response.result?.hasMore ?? false;
    } catch (error) {
      const message = (error as Error).message;
      this.artistError = message.length > 0 ? message : '搜索失败';
    } finally {
      this.artistIsLoading = false;
      this.artistLoading = false;
    }
  }

  private async fetchPlaylists(offset: number, isFirst: boolean): Promise<void> {
    if (this.api === undefined) return;
    if (isFirst) {
      this.playlistIsLoading = true;
    } else {
      this.playlistLoading = true;
    }
    this.playlistError = '';
    try {
      const response = await this.api.searchPlaylists(this.submittedKeyword, offset, PAGE_SIZE);
      const items: SearchPlaylistItem[] = response.result?.playlists ?? [];
      this.playlists = isFirst ? items : [...this.playlists, ...items];
      this.playlistOffset = offset;
      this.playlistHasMore = response.result?.hasMore ?? false;
    } catch (error) {
      const message = (error as Error).message;
      this.playlistError = message.length > 0 ? message : '搜索失败';
    } finally {
      this.playlistIsLoading = false;
      this.playlistLoading = false;
    }
  }

  build() {
    Column({ space: 12 }) {
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

        Text('搜索')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .alignSelf(ItemAlign.Center)
          .margin({ left: 12 })
      }
      .width('100%')

      Row({ space: 8 }) {
        TextInput({ text: this.keyword, placeholder: '搜索歌曲、歌手、专辑' })
          .layoutWeight(1)
          .height(36)
          .fontSize(14)
          .backgroundColor($r('app.color.surface_input'))
          .borderRadius(18)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.keyword = value;
            this.scheduleSuggest(value);
          })
          .onSubmit(() => {
            this.submitWithKeyword(this.keyword);
          })

        Button() {
          Image($r('app.media.ic_search'))
            .width(18)
            .height(18)
            .fillColor($r('app.color.icon_primary'))
        }
        .type(ButtonType.Circle)
        .width(36)
        .height(36)
        .backgroundColor($r('app.color.surface_subtle'))
        .onClick(() => {
          this.submitWithKeyword(this.keyword);
        })
      }
      .width('100%')

      if (this.submittedKeyword.length > 0) {
        SearchTabBar({
          activeTab: this.activeTab,
          onTabChange: (type: SearchType): void => {
            this.onTabChange(type);
          }
        })
      }

      if (this.submittedKeyword.length === 0) {
        if (this.keyword.trim().length > 0) {
          SearchSuggestList({
            keywords: this.suggestKeywords,
            loading: this.suggestLoading,
            onItemClick: (word: string): void => {
              this.submitWithKeyword(word);
            }
          })
        } else {
          Column({ space: 8 }) {
            Row() {
              Text('热搜榜')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)
            }
            .width('100%')

            HotSearchList({
              onItemClick: (word: string): void => {
                this.submitWithKeyword(word);
              }
            })
          }
          .layoutWeight(1)
          .width('100%')
        }
      } else {
        if (this.activeTab === 'song') {
          SearchSongResultList({
            songs: this.songs,
            loadingMore: this.songLoading,
            hasMore: this.songHasMore,
            isLoading: this.songIsLoading,
            errorMessage: this.songError,
            onLoadMore: (): void => {
              this.onLoadMore();
            }
          })
        } else if (this.activeTab === 'album') {
          SearchAlbumResultList({
            albums: this.albums,
            loadingMore: this.albumLoading,
            hasMore: this.albumHasMore,
            isLoading: this.albumIsLoading,
            errorMessage: this.albumError,
            onLoadMore: (): void => {
              this.onLoadMore();
            }
          })
        } else if (this.activeTab === 'artist') {
          SearchArtistResultList({
            artists: this.artists,
            loadingMore: this.artistLoading,
            hasMore: this.artistHasMore,
            isLoading: this.artistIsLoading,
            errorMessage: this.artistError,
            onLoadMore: (): void => {
              this.onLoadMore();
            }
          })
        } else if (this.activeTab === 'playlist') {
          SearchPlaylistResultList({
            playlists: this.playlists,
            loadingMore: this.playlistLoading,
            hasMore: this.playlistHasMore,
            isLoading: this.playlistIsLoading,
            errorMessage: this.playlistError,
            onLoadMore: (): void => {
              this.onLoadMore();
            }
          })
        }
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: SUBPAGE_BOTTOM_PADDING_VP })
  }
}
