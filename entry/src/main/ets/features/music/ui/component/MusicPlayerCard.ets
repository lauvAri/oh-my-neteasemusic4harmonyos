import { promptAction, router } from '@kit.ArkUI';
import { SongApi } from '../../data/api/SongApi';
import { SongRepositoryImpl } from '../../data/repository/SongRepositoryImpl';
import { SongArtist, SongDetail, SongPrivilege } from '../../domain/model/SongModels';
import { GetSongDetailUseCase, SongDetailAggregate } from '../../domain/usecase/GetSongDetailUseCase';
import { PlayerEngine } from '../../service/PlayerEngine';

interface ParsedLyricLine {
  timeMs: number;
  text: string;
}

const TEXT_PRIMARY: string = '#ffffff';
const TEXT_SECONDARY: string = 'rgba(255, 255, 255, 0.78)';
const TEXT_TERTIARY: string = 'rgba(255, 255, 255, 0.52)';
const TEXT_MUTED: string = 'rgba(255, 255, 255, 0.35)';
const ERROR_COLOR: string = '#ffb4b4';
const CONTROL_GRAY: string = 'rgba(128, 128, 128, 0.30)';
const PLAY_BUTTON_GRAY: string = 'rgba(128, 128, 128, 0.60)';
const SLIDER_TRACK_GRAY: string = 'rgba(128, 128, 128, 0.30)';

@Component
export struct MusicPlayerCard {
  @Prop songId: number = 1969519579;

  @StorageLink('miniPlayerPlaying') private playing: boolean = false;
  @StorageLink('selectedSongId') @Watch('onSelectedSongChanged') private selectedSongId: number = 0;
  @StorageLink('playerCurrentMs') @Watch('onCurrentMsChanged') private currentMs: number = 0;
  @StorageLink('playerDurationMs') private durationMs: number = 0;
  @StorageLink('currentSongRawLyric') @Watch('onLyricStorageChanged') private rawLyricText: string = '';
  @StorageLink('currentSongLyric') @Watch('onLyricStorageChanged') private storedLyricText: string = '';
  @StorageLink('currentSongLyricError') private storedLyricErrorText: string = '';
  @StorageLink('currentSongLyricLoading') private storedLyricLoading: boolean = false;

  @State private loading: boolean = false;
  @State private statusText: string = '点击播放按钮开始';
  @State private detailLoading: boolean = true;
  @State private detailErrorText: string = '';
  @State private songDetail: SongDetail | null = null;
  @State private songPrivilege: SongPrivilege | null = null;
  @State private sliderValue: number = 0;
  @State @Watch('onShowLyricChanged') private showLyric: boolean = false;
  @State private lyricLines: ParsedLyricLine[] = [];

  private songRepository: SongRepositoryImpl = new SongRepositoryImpl(new SongApi());
  private readonly getSongDetailUseCase: GetSongDetailUseCase =
    new GetSongDetailUseCase(this.songRepository);
  private engine: PlayerEngine = PlayerEngine.getInstance();
  private lyricScroller: Scroller = new Scroller();
  private lastScrolledLyricIndex: number = -2;
  private navDebounceTimestamp: number = 0;

  aboutToAppear(): void {
    this.reloadCurrentSongData();
  }

  private getActiveSongId(): number {
    const stored = AppStorage.get<number>('selectedSongId') ?? 0;
    return stored > 0 ? stored : this.songId;
  }

  private reloadCurrentSongData(): void {
    this.loadSongDetail(this.songId);
    this.refreshParsedLyrics();
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
    this.lyricLines = this.parseLyricLines(this.rawLyricText);
    if (this.lyricLines.length === 0 && this.storedLyricText.length > 0) {
      this.lyricLines = this.storedLyricText.split('\n').map((line: string) => {
        const item: ParsedLyricLine = {
          timeMs: -1,
          text: line
        };
        return item;
      });
    }
  }

  private parseLyricLines(rawLyric: string): ParsedLyricLine[] {
    const lines = rawLyric.split('\n');
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

      const minutes = Number.parseInt(timeMatch[1], 10);
      const seconds = Number.parseInt(timeMatch[2], 10);
      const millisecondText = timeMatch[3] === undefined ? '0' : timeMatch[3];
      const milliseconds = Number.parseInt(millisecondText.padEnd(3, '0'), 10);
      const item: ParsedLyricLine = {
        timeMs: minutes * 60000 + seconds * 1000 + milliseconds,
        text: text
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
    this.loadSongDetail(this.selectedSongId);
    this.refreshParsedLyrics();
  }

  private getArtistNames(): string {
    if (!this.songDetail || this.songDetail.ar.length === 0) {
      return '未知歌手';
    }
    return this.songDetail.ar.map((artist: SongArtist) => artist.name).join(' / ');
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

  build() {
    Column() {
      this.MediaStage()

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

      Row({ space: 28 }) {
        Button() {
          Image($r('app.media.ic_skip_previous'))
            .width(26)
            .height(26)
            .fillColor(TEXT_PRIMARY)
        }
          .type(ButtonType.Circle)
          .width(52)
          .height(52)
          .backgroundColor(CONTROL_GRAY)
          .onClick(async () => {
            const moved = await this.engine.prev();
            if (!moved) {
              promptAction.showToast({ message: '已是第一首' });
            }
          })

        Button() {
          if (this.loading) {
            LoadingProgress()
              .width(28)
              .height(28)
              .color(TEXT_PRIMARY)
          } else {
            Image(this.playing ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
              .width(28)
              .height(28)
              .fillColor(TEXT_PRIMARY)
          }
        }
          .type(ButtonType.Circle)
          .width(68)
          .height(68)
          .backgroundColor(PLAY_BUTTON_GRAY)
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
          .width(52)
          .height(52)
          .backgroundColor(CONTROL_GRAY)
          .onClick(async () => {
            const moved = await this.engine.next();
            if (!moved) {
              promptAction.showToast({ message: '已是最后一首' });
            }
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 14 })

      if (this.statusText.length > 0) {
        Text(this.statusText)
          .fontSize(11)
          .fontColor(TEXT_TERTIARY)
          .textAlign(TextAlign.Center)
          .margin({ top: 8 })
      }

      if (this.songDetail) {
        Row({ space: 12 }) {
          Text(`时长 ${this.getDurationText()}`)
            .fontSize(11)
            .fontColor(TEXT_MUTED)
          Text(`音质上限 ${this.getQualityText()}`)
            .fontSize(11)
            .fontColor(TEXT_MUTED)
        }
        .margin({ top: 4 })
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
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

        Text(this.getArtistNames())
          .fontSize(14)
          .fontColor(TEXT_SECONDARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 2 })
          .onClick(() => {
            if (this.songDetail && this.songDetail.ar.length > 0) {
              const now = Date.now();
              if (now - this.navDebounceTimestamp < 800) {
                return;
              }
              this.navDebounceTimestamp = now;
              const artistId = this.songDetail.ar[0].id;
              AppStorage.setOrCreate('pendingNavTarget',
                JSON.stringify({ page: 'ArtistDetailPage', id: artistId }));
              router.back();
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
            Text(line.text)
              .fontSize(this.isActiveLyricLine(index) ? 19 : 15)
              .fontWeight(this.isActiveLyricLine(index) ? FontWeight.Medium : FontWeight.Regular)
              .fontColor(this.isActiveLyricLine(index) ? TEXT_PRIMARY : TEXT_TERTIARY)
              .lineHeight(this.isActiveLyricLine(index) ? 30 : 26)
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding({ left: 12, right: 12 })
          }
        }, (line: ParsedLyricLine, index: number) => `${index}-${line.timeMs}`)
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
}
