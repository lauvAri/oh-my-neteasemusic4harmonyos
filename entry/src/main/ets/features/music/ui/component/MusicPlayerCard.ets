import { promptAction, router } from '@kit.ArkUI';
import common from '@ohos.app.ability.common';
import { SongApi } from '../../data/api/SongApi';
import { LikeApi } from '../../data/api/LikeApi';
import { LikeListApi } from '../../data/api/LikeListApi';
import { SongRepositoryImpl } from '../../data/repository/SongRepositoryImpl';
import { SongArtist, SongDetail, SongPrivilege } from '../../domain/model/SongModels';
import { GetSongDetailUseCase, SongDetailAggregate } from '../../domain/usecase/GetSongDetailUseCase';
import { PlayerEngine, PlaybackMode } from '../../service/PlayerEngine';
import { Song } from '../../domain/model/Song';
import { SessionStore } from '../../../../common/storage/SessionStore';

interface ParsedLyricLine {
  timeMs: number;
  text: string;
  translation: string;
  romaji: string;
}

enum LyricSecondaryMode {
  TRANSLATION = 0,
  ROMAJI = 1,
  ORIGINAL = 2
}

type ActiveSheet = 'queue' | 'artist';

const TEXT_PRIMARY: string = '#ffffff';
const TEXT_SECONDARY: string = 'rgba(255, 255, 255, 0.78)';
const TEXT_TERTIARY: string = 'rgba(255, 255, 255, 0.52)';
const TEXT_MUTED: string = 'rgba(255, 255, 255, 0.35)';
const ERROR_COLOR: string = '#ffb4b4';
const CONTROL_GRAY: string = 'rgba(128, 128, 128, 0.30)';
const PLAY_BUTTON_GRAY: string = 'rgba(128, 128, 128, 0.60)';
const SLIDER_TRACK_GRAY: string = 'rgba(128, 128, 128, 0.30)';
const TOGGLE_BORDER_COLOR: string = 'rgba(255, 255, 255, 0.40)';
const TOGGLE_BORDER_COLOR_OFF: string = 'rgba(255, 255, 255, 0.20)';

@Component
export struct MusicPlayerCard {
  @Prop songId: number = 1969519579;

  @StorageLink('miniPlayerPlaying') private playing: boolean = false;
  @StorageLink('selectedSongId') @Watch('onSelectedSongChanged') private selectedSongId: number = 0;
  @StorageLink('playbackMode') private playbackMode: number = 0;
  @StorageLink('playQueue') private playQueue: Song[] = [];
  @StorageLink('currentQueueIndex') private currentQueueIndex: number = -1;
  @StorageLink('playerCurrentMs') @Watch('onCurrentMsChanged') private currentMs: number = 0;
  @StorageLink('playerDurationMs') private durationMs: number = 0;
  @StorageLink('currentSongRawLyric') @Watch('onLyricStorageChanged') private rawLyricText: string = '';
  @StorageLink('currentSongLyric') @Watch('onLyricStorageChanged') private storedLyricText: string = '';
  @StorageLink('currentSongLyricError') private storedLyricErrorText: string = '';
  @StorageLink('currentSongLyricLoading') private storedLyricLoading: boolean = false;
  @StorageLink('currentSongTranslationLyric') @Watch('onLyricStorageChanged') private storedTranslationText: string = '';
  @StorageLink('currentSongRomajiLyric') @Watch('onLyricStorageChanged') private storedRomajiText: string = '';
  @StorageLink('currentSongHasTranslation') @Watch('onLyricStorageChanged') private hasTranslation: boolean = false;
  @StorageLink('currentSongHasRomaji') @Watch('onLyricStorageChanged') private hasRomaji: boolean = false;

  @State private loading: boolean = false;
  @State private statusText: string = '点击播放按钮开始';
  @State private detailLoading: boolean = true;
  @State private detailErrorText: string = '';
  @State private songDetail: SongDetail | null = null;
  @State private songPrivilege: SongPrivilege | null = null;
  @State private sliderValue: number = 0;
  @State @Watch('onShowLyricChanged') private showLyric: boolean = false;
  @State private lyricLines: ParsedLyricLine[] = [];
  @State private secondaryMode: LyricSecondaryMode = LyricSecondaryMode.TRANSLATION;
  @State private showOnlyTranslation: boolean = true;
  @State private activeSheet: ActiveSheet | null = null;
  @State private isLiked: boolean = false;
  @State private likePending: boolean = false;

  private songRepository: SongRepositoryImpl = new SongRepositoryImpl(new SongApi());
  private readonly getSongDetailUseCase: GetSongDetailUseCase =
    new GetSongDetailUseCase(this.songRepository);
  private engine: PlayerEngine = PlayerEngine.getInstance();
  private lyricScroller: Scroller = new Scroller();
  private lastScrolledLyricIndex: number = -2;
  private navDebounceTimestamp: number = 0;
  private likeApi?: LikeApi;
  private likeListApi?: LikeListApi;
  private sessionStore?: SessionStore;

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    this.sessionStore = new SessionStore(context);
    this.likeApi = new LikeApi(context);
    this.likeListApi = new LikeListApi(context);
    this.songRepository.setLikeApi(this.likeApi);
    this.reloadCurrentSongData();
    // Preload liked song list if not yet loaded
    const userId = AppStorage.get<number>('userId');
    if (userId !== undefined && userId > 0) {
      this.songRepository.loadLikedSongIds(userId, context).catch((_e: Error) => {});
    }
  }

  private getActiveSongId(): number {
    const stored = AppStorage.get<number>('selectedSongId') ?? 0;
    return stored > 0 ? stored : this.songId;
  }
  private reloadCurrentSongData(): void {
    this.loadSongDetail(this.songId);
    this.refreshParsedLyrics();
    this.isLiked = SongRepositoryImpl.isLikedSong(this.songId);
  }

  private async loadSongDetail(targetSongId: number): Promise<void> {
    this.showLyric = false;
    this.lastScrolledLyricIndex = -2;

    const cached = this.songRepository.getCachedDetail(targetSongId);
    if (cached !== null) {
      this.songDetail = cached.detail;
      this.songPrivilege = cached.privilege;
      this.detailErrorText = '';
      this.detailLoading = false;
      AppStorage.setOrCreate<string>('currentDetailCover', cached.detail.al.picUrl);
      return;
    }

    this.detailLoading = true;
    this.detailErrorText = '';
    this.songDetail = null;
    this.songPrivilege = null;
    try {
      const aggregate: SongDetailAggregate = await this.getSongDetailUseCase.execute(targetSongId);
      if (targetSongId !== this.songId && targetSongId !== this.selectedSongId) {
        return;
      }
      this.songDetail = aggregate.detail;
      this.songPrivilege = aggregate.privilege;
      AppStorage.setOrCreate<string>('currentDetailCover', aggregate.detail.al.picUrl);
    } catch (error) {
      if (targetSongId !== this.songId && targetSongId !== this.selectedSongId) {
        return;
      }
      const message = (error as Error).message;
      this.detailErrorText = message.length > 0 ? message : '歌曲详情加载失败';
    } finally {
      if (targetSongId === this.songId || targetSongId === this.selectedSongId) {
        this.detailLoading = false;
      }
    }
  }

  private refreshParsedLyrics(): void {
    this.lyricLines = this.parseLyricLines(this.rawLyricText,
      this.storedTranslationText, this.storedRomajiText);
    if (this.lyricLines.length === 0 && this.storedLyricText.length > 0) {
      this.lyricLines = this.storedLyricText.split('\n').map((line: string) => {
        const item: ParsedLyricLine = {
          timeMs: -1,
          text: line,
          translation: '',
          romaji: ''
        };
        return item;
      });
    }
  }

  private parseTimeToMs(timeMatch: RegExpMatchArray): number {
    const minutes = Number.parseInt(timeMatch[1], 10);
    const seconds = Number.parseInt(timeMatch[2], 10);
    const millisecondText = timeMatch[3] === undefined ? '0' : timeMatch[3];
    const milliseconds = Number.parseInt(millisecondText.padEnd(3, '0'), 10);
    return minutes * 60000 + seconds * 1000 + milliseconds;
  }

  private parseLyricMap(rawLyric: string): Map<number, string> {
    const map = new Map<number, string>();
    if (rawLyric.length === 0) {
      return map;
    }
    const lines = rawLyric.split('\n');
    lines.forEach((line: string) => {
      const trimmed = line.trim();
      if (trimmed.length === 0 || trimmed.startsWith('{')) {
        return;
      }
      const timeMatch = trimmed.match(/\[(\d{2}):(\d{2})(?:\.(\d{1,3}))?\]/);
      if (timeMatch === null) {
        return;
      }
      const text = trimmed
        .replace(/\[[^\]]*\]/g, '')
        .replace(/\([^)]*\)/g, '')
        .trim();
      if (text.length === 0) {
        return;
      }
      map.set(this.parseTimeToMs(timeMatch), text);
    });
    return map;
  }

  private parseLyricLines(rawLyric: string, translationLyric: string, romajiLyric: string): ParsedLyricLine[] {
    const lines = rawLyric.split('\n');
    const translationMap = this.parseLyricMap(translationLyric);
    const romajiMap = this.parseLyricMap(romajiLyric);
    const parsed: ParsedLyricLine[] = [];
    lines.forEach((line: string) => {
      const trimmed = line.trim();
      if (trimmed.length === 0 || trimmed.startsWith('{')) {
        return;
      }
      const timeMatch = trimmed.match(/\[(\d{2}):(\d{2})(?:\.(\d{1,3}))?\]/);
      if (timeMatch === null) {
        return;
      }
      const text = trimmed
        .replace(/\[[^\]]*\]/g, '')
        .replace(/\([^)]*\)/g, '')
        .trim();
      if (text.length === 0) {
        return;
      }
      const timeMs = this.parseTimeToMs(timeMatch);
      const item: ParsedLyricLine = {
        timeMs: timeMs,
        text: text,
        translation: translationMap.get(timeMs) ?? '',
        romaji: romajiMap.get(timeMs) ?? ''
      };
      parsed.push(item);
    });
    return parsed;
  }

  private getCurrentLyricIndex(): number {
    let activeIndex = -1;
    this.lyricLines.forEach((line: ParsedLyricLine, index: number) => {
      if (line.timeMs >= 0 && this.currentMs >= line.timeMs) {
        activeIndex = index;
      }
    });
    return activeIndex;
  }

  private isActiveLyricLine(index: number): boolean {
    return this.getCurrentLyricIndex() === index;
  }

  private syncLyricScroll(): void {
    if (!this.showLyric || this.storedLyricLoading || this.lyricLines.length === 0) {
      return;
    }
    const currentLyricIndex = this.getCurrentLyricIndex();
    if (currentLyricIndex < 0 || currentLyricIndex === this.lastScrolledLyricIndex) {
      return;
    }
    this.lastScrolledLyricIndex = currentLyricIndex;
    this.lyricScroller.scrollToIndex(currentLyricIndex + 1, true, ScrollAlign.CENTER);
  }

  private onCurrentMsChanged(): void {
    this.syncLyricScroll();
  }

  private onShowLyricChanged(): void {
    this.syncLyricScroll();
  }

  private onLyricStorageChanged(): void {
    this.resetLyricMode();
    this.refreshParsedLyrics();
    this.syncLyricScroll();
  }
  private onSelectedSongChanged(): void {
    if (this.selectedSongId <= 0) {
      return;
    }
    if (this.songDetail !== null && this.songDetail.id === this.selectedSongId) {
      return;
    }
    this.statusText = '播放中';
    this.isLiked = SongRepositoryImpl.isLikedSong(this.selectedSongId);
    this.loadSongDetail(this.selectedSongId);
    this.refreshParsedLyrics();
  }

  private resetLyricMode(): void {
    this.secondaryMode = LyricSecondaryMode.TRANSLATION;
    this.showOnlyTranslation = true;
  }

  private getArtistNames(): string {
    if (!this.songDetail || this.songDetail.ar.length === 0) {
      return '未知歌手';
    }
    return this.songDetail.ar.map((artist: SongArtist) => artist.name).join(' / ');
  }

  private getArtistNamesWithHint(): string {
    if (!this.songDetail || this.songDetail.ar.length === 0) {
      return '未知歌手';
    }
    const names = this.songDetail.ar.map((artist: SongArtist) => artist.name).join(' / ');
    if (this.songDetail.ar.length > 1) {
      return `${names}  ›`;
    }
    return names;
  }

  private navigateToArtist(artistId: number): void {
    AppStorage.setOrCreate('pendingNavTarget',
      JSON.stringify({ page: 'ArtistDetailPage', id: artistId }));
    router.back();
  }

  private getAliasText(): string {
    if (!this.songDetail || this.songDetail.alia.length === 0) {
      return '';
    }
    return this.songDetail.alia[0];
  }

  private getDurationText(): string {
    if (!this.songDetail) {
      return '--:--';
    }
    const totalSeconds = Math.floor(this.songDetail.dt / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    const secondText = seconds < 10 ? `0${seconds}` : `${seconds}`;
    return `${minutes}:${secondText}`;
  }

  private getQualityText(): string {
    if (!this.songPrivilege) {
      return '未知';
    }
    return this.songPrivilege.maxBrLevel;
  }

  private formatTime(ms: number): string {
    const totalSeconds = Math.floor(ms / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    const secondText = seconds < 10 ? `0${seconds}` : `${seconds}`;
    return `${minutes}:${secondText}`;
  }

  private getPlaybackModeIcon(): Resource {
    if (this.playbackMode === PlaybackMode.REPEAT_ONE) {
      return $r('app.media.ic_repeat_one_play');
    }
    if (this.playbackMode === PlaybackMode.SHUFFLE) {
      return $r('app.media.ic_shuffle_play');
    }
    return $r('app.media.ic_circle_play');
  }

  private getPlaybackModeLabel(): string {
    if (this.playbackMode === PlaybackMode.REPEAT_ONE) {
      return '单曲循环';
    }
    if (this.playbackMode === PlaybackMode.SHUFFLE) {
      return '随机播放';
    }
    return '顺序播放';
  }

  private getQueueSongArtistText(song: Song): string {
    if (song.ar.length === 0) {
      return '未知歌手';
    }
    return song.ar.map((artist: SongArtist) => artist.name).join(' / ');
  }

  private getQueueSongDurationText(song: Song): string {
    const totalSeconds = Math.floor(song.dt / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    const secondText = seconds < 10 ? `0${seconds}` : `${seconds}`;
    return `${minutes}:${secondText}`;
  }

  private async playSong(): Promise<void> {
    this.loading = true;
    this.statusText = '正在请求播放链接...';
    try {
      await this.engine.playSong(this.getActiveSongId());
      this.statusText = '播放中';
    } catch (error) {
      const message = (error as Error).message;
      this.statusText = message.length > 0 ? message : '播放失败';
      promptAction.showToast({ message: this.statusText });
    } finally {
      this.loading = false;
    }
  }

  private async pauseSong(): Promise<void> {
    try {
      await this.engine.pause();
      this.statusText = '已暂停';
    } catch (error) {
      promptAction.showToast({ message: '暂停失败' });
    }
  }

  @Builder
  private PlaybackModeButton() {
    Button() {
      Image(this.getPlaybackModeIcon())
        .width(26)
        .height(26)
        .fillColor(TEXT_PRIMARY)
    }
      .type(ButtonType.Circle)
      .width(48)
      .height(48)
      .backgroundColor(Color.Transparent)
      .stateEffect(true)
      .onClick(() => {
        this.engine.cyclePlaybackMode();
        promptAction.showToast({ message: this.getPlaybackModeLabel() });
      })
  }

  @Builder
  private FavoriteButton() {
    Button() {
      Image(this.isLiked ? $r('app.media.ic_favorite_filled') : $r('app.media.ic_favorite'))
        .width(20)
        .height(20)
        .fillColor(this.isLiked ? $r('app.color.text_danger') : TEXT_TERTIARY)
    }
      .type(ButtonType.Circle)
      .width(36)
      .height(36)
      .backgroundColor(Color.Transparent)
      .stateEffect(true)
      .enabled(!this.likePending)
      .onClick(() => {
        this.toggleLike();
      })
  }

  private async toggleLike(): Promise<void> {
    if (this.likePending) {
      return;
    }
    const songId = this.getActiveSongId();
    if (songId === 0) {
      return;
    }

    const cookie = await this.sessionStore?.getCookie() ?? '';
    if (cookie.length === 0) {
      promptAction.showToast({ message: '请先登录' });
      return;
    }

    const prev = this.isLiked;
    this.isLiked = !prev;
    this.likePending = true;
    try {
      await this.songRepository.toggleSongLike(songId, !prev);
      if (!prev) {
        SongRepositoryImpl.addLikedSongId(songId);
      } else {
        SongRepositoryImpl.removeLikedSongId(songId);
      }
      promptAction.showToast({ message: !prev ? '已添加到我喜欢' : '已取消喜欢' });
    } catch (error) {
      this.isLiked = prev;
      promptAction.showToast({ message: (error as Error).message });
    } finally {
      this.likePending = false;
    }
  }

  @Builder
  private QueueButton() {
    Button() {
      Image($r('app.media.ic_music_queue'))
        .width(26)
        .height(26)
        .fillColor(TEXT_PRIMARY)
    }
      .type(ButtonType.Circle)
      .width(48)
      .height(48)
      .backgroundColor(Color.Transparent)
      .stateEffect(true)
      .onClick(() => {
        this.activeSheet = 'queue';
      })
  }

  @Builder
  private SheetRouter() {
    if (this.activeSheet === 'queue') {
      this.QueueSheet();
    } else if (this.activeSheet === 'artist') {
      this.ArtistPickerSheet();
    }
  }

  @Builder
  private QueueSheet() {
    Column() {
      Text(`当前播放 (${this.playQueue.length})`)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_PRIMARY)
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 4, bottom: 12 })

      Divider()
        .color('rgba(255, 255, 255, 0.10)')
        .width('100%')

      if (this.playQueue.length === 0) {
        Column() {
          Text('暂无播放队列')
            .fontSize(14)
            .fontColor(TEXT_TERTIARY)
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.playQueue, (song: Song, index: number) => {
            ListItem() {
              this.QueueRow(song, index)
            }
          }, (song: Song, index: number) => `${index}-${song.id}`)
        }
        .width('100%')
        .layoutWeight(1)
        .listDirection(Axis.Vertical)
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ top: 12, bottom: 16 })
  }

  @Builder
  private QueueRow(song: Song, index: number) {
    Row({ space: 12 }) {
      if (index === this.currentQueueIndex) {
        Image($r('app.media.ic_play'))
          .width(14)
          .height(14)
          .fillColor($r('app.color.text_brand'))
      } else {
        Text(`${index + 1}`)
          .fontSize(13)
          .fontColor(TEXT_TERTIARY)
          .width(14)
          .textAlign(TextAlign.Center)
      }

      Image(song.al.picUrl)
        .width(44)
        .height(44)
        .borderRadius(6)
        .objectFit(ImageFit.Cover)

      Column({ space: 4 }) {
        Text(song.name)
          .fontSize(15)
          .fontWeight(index === this.currentQueueIndex ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(index === this.currentQueueIndex ? $r('app.color.text_brand') : TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${this.getQueueSongArtistText(song)} - ${song.al.name}`)
          .fontSize(12)
          .fontColor(TEXT_TERTIARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text(this.getQueueSongDurationText(song))
        .fontSize(12)
        .fontColor(TEXT_TERTIARY)
        .margin({ right: 4 })
    }
    .width('100%')
    .padding({ top: 8, bottom: 8, left: 4, right: 4 })
    .onClick(() => {
      this.activeSheet = null;
      this.engine.playSong(song.id).catch((error: Error) => {
        console.error(`queue switch failed: ${error.message}`);
      });
    })
  }

  @Builder
  private ArtistPickerSheet() {
    Column() {
      Text('选择歌手')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_PRIMARY)
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 4, bottom: 12 })

      Divider()
        .color('rgba(255, 255, 255, 0.10)')
        .width('100%')

      if (!this.songDetail || this.songDetail.ar.length === 0) {
        Column() {
          Text('暂无歌手信息')
            .fontSize(14)
            .fontColor(TEXT_TERTIARY)
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.songDetail.ar, (artist: SongArtist) => {
            ListItem() {
              this.ArtistPickerRow(artist)
            }
          }, (artist: SongArtist) => `${artist.id}`)
        }
        .width('100%')
        .layoutWeight(1)
        .listDirection(Axis.Vertical)
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ top: 12, bottom: 16 })
  }

  @Builder
  private ArtistPickerRow(artist: SongArtist) {
    Row({ space: 12 }) {
      Image($r('app.media.ic_favorite'))
        .width(18)
        .height(18)
        .fillColor(TEXT_TERTIARY)

      Text(artist.name)
        .fontSize(16)
        .fontColor(TEXT_PRIMARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 8 })
    .onClick(() => {
      this.activeSheet = null;
      this.navigateToArtist(artist.id);
    })
  }

  build() {
    Column() {
      this.MediaStage()

      this.LyricModeRow()
      Slider({
        value: this.currentMs,
        min: 0,
        max: this.durationMs > 0 ? this.durationMs : 1,
        step: 1000,
        style: SliderStyle.OutSet
      })
        .blockColor(TEXT_PRIMARY)
        .trackColor(SLIDER_TRACK_GRAY)
        .selectedColor(TEXT_PRIMARY)
        .width('100%')
        .padding({ left: 12, right: 12 })
        .onChange((value: number, mode: SliderChangeMode) => {
          this.sliderValue = value;
          if (mode === SliderChangeMode.End && this.durationMs > 0) {
            const targetMs = Math.floor(this.sliderValue);
            this.engine.seekTo(targetMs).catch((error: Error) => {
              console.error(`seek failed: ${error.message}`);
            });
          }
        })

      Row() {
        Text(this.formatTime(this.currentMs))
          .fontSize(11)
          .fontColor(TEXT_TERTIARY)
        Blank()
        Text(this.formatTime(this.durationMs))
          .fontSize(11)
          .fontColor(TEXT_TERTIARY)
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .margin({ top: 2 })

      Row({ space: 16 }) {
        this.PlaybackModeButton()

        Row({ space: 24 }) {
          Button() {
            Image($r('app.media.ic_skip_previous'))
              .width(26)
              .height(26)
              .fillColor(TEXT_PRIMARY)
          }
            .type(ButtonType.Circle)
            .width(48)
            .height(48)
            .backgroundColor(Color.Transparent)
            .stateEffect(true)
            .onClick(async () => {
              const moved = await this.engine.prev();
              if (!moved) {
                promptAction.showToast({ message: '已是第一首' });
              }
            })

          Button() {
            if (this.loading) {
              LoadingProgress()
                .width(30)
                .height(30)
                .color(TEXT_PRIMARY)
            } else {
              Image(this.playing ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
                .width(30)
                .height(30)
                .fillColor(TEXT_PRIMARY)
            }
          }
            .type(ButtonType.Circle)
            .width(70)
            .height(70)
            .backgroundColor(Color.Transparent)
            .border({
              width: 1.5,
              color: 'rgba(255, 255, 255, 0.30)',
              style: BorderStyle.Solid
            })
            .stateEffect(true)
            .enabled(!this.loading)
            .onClick(async () => {
              if (this.playing) {
                await this.pauseSong();
              } else {
                await this.playSong();
              }
            })

          Button() {
            Image($r('app.media.ic_skip_next'))
              .width(26)
              .height(26)
              .fillColor(TEXT_PRIMARY)
          }
            .type(ButtonType.Circle)
            .width(48)
            .height(48)
            .backgroundColor(Color.Transparent)
            .stateEffect(true)
            .onClick(async () => {
              const moved = await this.engine.next();
              if (!moved) {
                promptAction.showToast({ message: '已是最后一首' });
              }
            })
        }

        this.QueueButton()
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 18 })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .bindSheet(this.activeSheet !== null, this.SheetRouter(), {
      height: '60%',
      showClose: false,
      dragBar: true,
      backgroundColor: '#1f2937',
      onDisappear: () => {
        this.activeSheet = null;
      }
    })
  }
  @Builder
  private LyricModeRow() {
    Row() {
      if (this.hasTranslation && this.hasRomaji) {
        this.TranslationRomajiToggle()
      } else if (this.hasTranslation) {
        this.TranslationOnlyToggle()
      } else {
        Blank()
      }
      Blank()
      this.FavoriteButton()
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .margin({ top: 2 })
  }

  @Builder
  private TranslationRomajiToggle() {
    Row({ space: 6 }) {
      Text('译')
        .fontSize(12)
        .fontWeight(this.secondaryMode === LyricSecondaryMode.TRANSLATION ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.secondaryMode === LyricSecondaryMode.TRANSLATION ? TEXT_PRIMARY : TEXT_MUTED)
        .decoration({ type: TextDecorationType.None })
      Text('/')
        .fontSize(12)
        .fontColor(TEXT_MUTED)
      Text('音')
        .fontSize(12)
        .fontWeight(this.secondaryMode === LyricSecondaryMode.ROMAJI ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.secondaryMode === LyricSecondaryMode.ROMAJI ? TEXT_PRIMARY : TEXT_MUTED)
        .decoration({ type: TextDecorationType.None })
    }
    .height(24)
    .padding({ left: 10, right: 10 })
    .borderRadius(12)
    .border({
      width: 1,
      color: TOGGLE_BORDER_COLOR,
      style: BorderStyle.Solid
    })
    .backgroundColor('rgba(0, 0, 0, 0)')
    .onClick(() => {
      switch (this.secondaryMode) {
        case LyricSecondaryMode.TRANSLATION:
          this.secondaryMode = LyricSecondaryMode.ROMAJI;
          break;
        case LyricSecondaryMode.ROMAJI:
          this.secondaryMode = LyricSecondaryMode.ORIGINAL;
          break;
        default:
          this.secondaryMode = LyricSecondaryMode.TRANSLATION;
      }
    })
  }

  @Builder
  private TranslationOnlyToggle() {
    Row() {
      Text('译')
        .fontSize(12)
        .fontWeight(this.showOnlyTranslation ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.showOnlyTranslation ? TEXT_PRIMARY : TEXT_MUTED)
        .decoration({
          type: this.showOnlyTranslation ? TextDecorationType.None : TextDecorationType.LineThrough,
          color: TEXT_MUTED
        })
    }
    .height(24)
    .padding({ left: 10, right: 10 })
    .borderRadius(12)
    .border({
      width: 1,
      color: this.showOnlyTranslation ? TOGGLE_BORDER_COLOR : TOGGLE_BORDER_COLOR_OFF,
      style: BorderStyle.Solid
    })
    .backgroundColor('rgba(0, 0, 0, 0)')
    .onClick(() => {
      this.showOnlyTranslation = !this.showOnlyTranslation;
    })
  }

  @Builder
  private MediaStage() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.detailLoading) {
        Stack({ alignContent: Alignment.Center }) {
          Column({ space: 12 }) {
            LoadingProgress()
              .width(36)
              .height(36)
              .color(TEXT_PRIMARY)
            Text('歌曲详情加载中...')
              .fontSize(13)
              .fontColor(TEXT_SECONDARY)
          }
        }
        .width('100%')
        .height('100%')
      } else if (this.detailErrorText.length > 0) {
        Stack({ alignContent: Alignment.Center }) {
          Column({ space: 14 }) {
            Text(this.detailErrorText)
              .fontSize(14)
              .fontColor(ERROR_COLOR)
              .textAlign(TextAlign.Center)
            Button('重试详情')
              .fontSize(13)
              .fontColor(TEXT_PRIMARY)
              .height(36)
              .padding({ left: 18, right: 18 })
              .backgroundColor(CONTROL_GRAY)
              .onClick(() => {
                this.loadSongDetail(this.getActiveSongId());
              })
          }
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height('100%')
      } else if (this.songDetail) {
        if (this.showLyric) {
          Stack({ alignContent: Alignment.Center }) {
            this.LyricsView()
          }
          .width('100%')
          .height('100%')
        } else {
          this.CoverView()
        }
      }
    }
    .layoutWeight(1)
    .width('100%')
  }

  @Builder
  private CoverView() {
    Column({ space: 18 }) {
      Image(this.songDetail ? this.songDetail.al.picUrl : '')
        .width('86%')
        .aspectRatio(1)
        .borderRadius(28)
        .objectFit(ImageFit.Cover)
        .shadow(ShadowStyle.OUTER_DEFAULT_MD)
        .onClick(() => {
          this.showLyric = true;
          this.lastScrolledLyricIndex = -2;
        })

      Column({ space: 4 }) {
        Text(this.songDetail ? this.songDetail.name : '')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Center)

        if (this.getAliasText().length > 0) {
          Text(this.getAliasText())
            .fontSize(12)
            .fontColor(TEXT_MUTED)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .textAlign(TextAlign.Center)
        }

        Text(this.getArtistNamesWithHint())
          .fontSize(14)
          .fontColor(TEXT_SECONDARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 2 })
          .onClick(() => {
            if (!this.songDetail || this.songDetail.ar.length === 0) {
              return;
            }
            const now = Date.now();
            if (now - this.navDebounceTimestamp < 800) {
              return;
            }
            this.navDebounceTimestamp = now;
            if (this.songDetail.ar.length === 1) {
              this.navigateToArtist(this.songDetail.ar[0].id);
            } else {
              this.activeSheet = 'artist';
            }
          })

        Text(`专辑：${this.songDetail ? this.songDetail.al.name : ''}`)
          .fontSize(12)
          .fontColor(TEXT_TERTIARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Center)
          .onClick(() => {
            if (this.songDetail) {
              const now = Date.now();
              if (now - this.navDebounceTimestamp < 800) {
                return;
              }
              this.navDebounceTimestamp = now;
              AppStorage.setOrCreate('pendingNavTarget',
                JSON.stringify({ page: 'AlbumDetailPage', id: this.songDetail.al.id }));
              router.back();
            }
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 4 })
  }

  @Builder
  private LyricsView() {
    List({ space: 14, scroller: this.lyricScroller, initialIndex: 0 }) {
      ListItem() {
        Column() {
          Blank()
        }
        .height(120)
        .width('100%')
      }

      if (this.storedLyricLoading) {
        ListItem() {
          Column({ space: 10 }) {
            LoadingProgress()
              .width(36)
              .height(36)
              .color(TEXT_PRIMARY)
            Text('歌词加载中...')
              .fontSize(13)
              .fontColor(TEXT_SECONDARY)
          }
          .width('100%')
          .height(220)
          .justifyContent(FlexAlign.Center)
        }
      } else if (this.storedLyricErrorText.length > 0) {
        ListItem() {
          Text(this.storedLyricErrorText)
            .fontSize(14)
            .fontColor(ERROR_COLOR)
            .width('100%')
            .textAlign(TextAlign.Center)
        }
      } else {
        ForEach(this.lyricLines, (line: ParsedLyricLine, index: number) => {
          ListItem() {
            Column({ space: 4 }) {
              Text(line.text)
                .fontSize(this.isActiveLyricLine(index) ? 19 : 15)
                .fontWeight(this.isActiveLyricLine(index) ? FontWeight.Medium : FontWeight.Regular)
                .fontColor(this.isActiveLyricLine(index) ? TEXT_PRIMARY : TEXT_TERTIARY)
                .lineHeight(this.isActiveLyricLine(index) ? 30 : 26)
                .textAlign(TextAlign.Center)
                .width('100%')
                .padding({ left: 12, right: 12 })
              if (this.shouldShowTranslation() && line.translation.length > 0) {
                Text(line.translation)
                  .fontSize(13)
                  .fontColor(TEXT_TERTIARY)
                  .lineHeight(20)
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .padding({ left: 12, right: 12 })
              }
              if (this.shouldShowRomaji() && line.romaji.length > 0) {
                Text(line.romaji)
                  .fontSize(12)
                  .fontColor(TEXT_MUTED)
                  .lineHeight(18)
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .padding({ left: 12, right: 12 })
              }
            }
            .alignItems(HorizontalAlign.Center)
            .width('100%')
          }
        }, (line: ParsedLyricLine, index: number) => `${index}-${line.timeMs}-${line.text}`)
      }

      ListItem() {
        Column() {
          Blank()
        }
        .height(160)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .onClick(() => {
      this.showLyric = false;
      this.lastScrolledLyricIndex = -2;
    })
  }

  private shouldShowTranslation(): boolean {
    if (!this.hasTranslation) {
      return false;
    }
    if (this.hasRomaji) {
      return this.secondaryMode === LyricSecondaryMode.TRANSLATION;
    }
    return this.showOnlyTranslation;
  }

  private shouldShowRomaji(): boolean {
    return this.hasRomaji && this.secondaryMode === LyricSecondaryMode.ROMAJI;
  }
}
