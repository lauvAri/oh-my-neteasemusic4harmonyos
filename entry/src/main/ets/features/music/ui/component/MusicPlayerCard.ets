import { promptAction } from '@kit.ArkUI';
import { SongApi } from '../../data/api/SongApi';
import { SongRepositoryImpl } from '../../data/repository/SongRepositoryImpl';
import { SongArtist, SongDetail, SongPrivilege } from '../../domain/model/SongModels';
import { GetSongDetailUseCase, SongDetailAggregate } from '../../domain/usecase/GetSongDetailUseCase';
import { PlayerEngine } from '../../service/PlayerEngine';

interface ParsedLyricLine {
  timeMs: number;
  text: string;
}

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
  @State private statusText: string = '点击播放歌曲';
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

  aboutToAppear(): void {
    this.reloadCurrentSongData();
  }

  private getActiveSongId(): number {
    if (this.selectedSongId > 0) {
      return this.selectedSongId;
    }
    return this.songId;
  }

  private reloadCurrentSongData(): void {
    this.loadSongDetail();
    this.refreshParsedLyrics();
  }

  private async loadSongDetail(): Promise<void> {
    const targetSongId = this.getActiveSongId();
    this.showLyric = false;
    this.lastScrolledLyricIndex = -2;
    this.detailLoading = true;
    this.detailErrorText = '';
    this.songDetail = null;
    this.songPrivilege = null;
    try {
      const aggregate: SongDetailAggregate = await this.getSongDetailUseCase.execute(targetSongId);
      if (targetSongId !== this.getActiveSongId()) {
        return;
      }
      this.songDetail = aggregate.detail;
      this.songPrivilege = aggregate.privilege;
    } catch (error) {
      if (targetSongId !== this.getActiveSongId()) {
        return;
      }
      const message = (error as Error).message;
      this.detailErrorText = message.length > 0 ? message : '歌曲详情加载失败';
    } finally {
      if (targetSongId === this.getActiveSongId()) {
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
    this.reloadCurrentSongData();
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
    Column({ space: 12 }) {
      if (this.detailLoading) {
        Text('歌曲详情加载中...')
          .fontSize(14)
          .fontColor('#666666')
      } else if (this.detailErrorText.length > 0) {
        Text(this.detailErrorText)
          .fontSize(14)
          .fontColor('#d94841')

        Button('重试详情')
          .onClick(() => {
            this.loadSongDetail();
          })
      } else if (this.songDetail) {
        if (this.showLyric) {
          List({ space: 8, scroller: this.lyricScroller, initialIndex: 0 }) {
            ListItem() {
              Column() {
                Blank()
              }
              .height(72)
              .width('100%')
            }

            if (this.storedLyricLoading) {
              ListItem() {
                Column({ space: 8 }) {
                  LoadingProgress()
                    .width(40)
                    .height(40)
                  Text('歌词加载中...')
                    .fontSize(14)
                    .fontColor('#666666')
                }
                .width('100%')
                .height(220)
                .justifyContent(FlexAlign.Center)
              }
            } else if (this.storedLyricErrorText.length > 0) {
              ListItem() {
                Text(this.storedLyricErrorText)
                  .fontSize(14)
                  .fontColor('#d94841')
                  .width('100%')
                  .textAlign(TextAlign.Center)
              }
            } else {
              ForEach(this.lyricLines, (line: ParsedLyricLine, index: number) => {
                ListItem() {
                  Text(line.text)
                    .fontSize(this.isActiveLyricLine(index) ? 18 : 15)
                    .fontWeight(this.isActiveLyricLine(index) ? FontWeight.Medium : FontWeight.Regular)
                    .fontColor(this.isActiveLyricLine(index) ? '#1677ff' : '#666666')
                    .lineHeight(30)
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
              .height(72)
              .width('100%')
            }
          }
          .width(260)
          .height(336)
          .padding(14)
          .borderRadius(16)
          .scrollBar(BarState.Off)
          .onClick(() => {
            this.showLyric = false;
            this.lastScrolledLyricIndex = -2;
          })
        } else {
          Image(this.songDetail.al.picUrl)
            .width(220)
            .height(220)
            .borderRadius(16)
            .objectFit(ImageFit.Cover)
            .onClick(() => {
              this.showLyric = true;
              this.lastScrolledLyricIndex = -2;
            })

          Text(this.songDetail.name)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)

          if (this.getAliasText().length > 0) {
            Text(this.getAliasText())
              .fontSize(13)
              .fontColor('#8a8a8a')
          }

          Text(this.getArtistNames())
            .fontSize(14)
            .fontColor('#555555')

          Text(`专辑：${this.songDetail.al.name}`)
            .fontSize(13)
            .fontColor('#666666')

          Row({ space: 12 }) {
            Text(`时长：${this.getDurationText()}`)
              .fontSize(12)
              .fontColor('#666666')

            Text(`音质上限：${this.getQualityText()}`)
              .fontSize(12)
              .fontColor('#666666')
          }
        }
      }

      Text(this.statusText)
        .fontSize(13)
        .fontColor('#666666')

      Slider({
        value: this.currentMs,
        min: 0,
        max: this.durationMs > 0 ? this.durationMs : 1,
        step: 1000,
        style: SliderStyle.OutSet
      })
        .blockColor('#1677ff')
        .trackColor('#d9dde3')
        .selectedColor('#1677ff')
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
          .fontSize(12)
          .fontColor('#666666')

        Blank()

        Text(this.formatTime(this.durationMs))
          .fontSize(12)
          .fontColor('#666666')
      }
      .width('100%')

      Row({ space: 20 }) {
        Button() {
          Image($r('app.media.ic_skip_previous'))
            .width(18)
            .height(18)
        }
          .type(ButtonType.Circle)
          .width(40)
          .height(40)
          .backgroundColor('#eceff3')
          .onClick(() => {
            promptAction.showToast({ message: '上一首暂未接入' });
          })

        Button() {
          if (this.loading) {
            Text('...')
              .fontSize(14)
              .fontColor('#1f2937')
          } else {
            Image(this.playing ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
              .width(16)
              .height(16)
          }
        }
          .type(ButtonType.Circle)
          .width(44)
          .height(44)
          .backgroundColor('#e5e7eb')
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
            .width(18)
            .height(18)
        }
          .type(ButtonType.Circle)
          .width(40)
          .height(40)
          .backgroundColor('#eceff3')
          .onClick(() => {
            promptAction.showToast({ message: '下一首暂未接入' });
          })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding(16)
    .backgroundColor('#f7f8fa')
    .borderRadius(16)
  }
}
