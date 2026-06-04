import { promptAction } from '@kit.ArkUI';
import { SongApi } from '../../data/api/SongApi';
import { SongRepositoryImpl } from '../../data/repository/SongRepositoryImpl';
import { SongArtist, SongDetail, SongPrivilege } from '../../domain/model/SongModels';
import { GetSongDetailUseCase, SongDetailAggregate } from '../../domain/usecase/GetSongDetailUseCase';
import { PlayerEngine } from '../../service/PlayerEngine';

@Component
export struct MusicPlayerCard {
  @Prop songId: number = 1969519579;

  @StorageLink('miniPlayerPlaying') private playing: boolean = false;
  @StorageLink('playerCurrentMs') private currentMs: number = 0;
  @StorageLink('playerDurationMs') private durationMs: number = 0;

  @State private loading: boolean = false;
  @State private statusText: string = '点击播放歌曲';
  @State private detailLoading: boolean = true;
  @State private detailErrorText: string = '';
  @State private songDetail: SongDetail | null = null;
  @State private songPrivilege: SongPrivilege | null = null;
  @State private sliderValue: number = 0;

  private songRepository: SongRepositoryImpl = new SongRepositoryImpl(new SongApi());
  private readonly getSongDetailUseCase: GetSongDetailUseCase =
    new GetSongDetailUseCase(this.songRepository);
  private engine: PlayerEngine = PlayerEngine.getInstance();

  aboutToAppear(): void {
    this.loadSongDetail();
  }

  private async loadSongDetail(): Promise<void> {
    this.detailLoading = true;
    this.detailErrorText = '';
    try {
      const aggregate: SongDetailAggregate = await this.getSongDetailUseCase.execute(this.songId);
      this.songDetail = aggregate.detail;
      this.songPrivilege = aggregate.privilege;
    } catch (error) {
      const message = (error as Error).message;
      this.detailErrorText = message.length > 0 ? message : '歌曲详情加载失败';
    } finally {
      this.detailLoading = false;
    }
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

  private getProgressValue(): number {
    if (this.durationMs <= 0) {
      return 0;
    }
    return this.currentMs / this.durationMs;
  }

  private async playSong(): Promise<void> {
    this.loading = true;
    this.statusText = '正在请求播放链接...';
    try {
      await this.engine.playSong(this.songId);
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
        Image(this.songDetail.al.picUrl)
          .width(220)
          .height(220)
          .borderRadius(16)
          .objectFit(ImageFit.Cover)

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

      Text(this.statusText)
        .fontSize(13)
        .fontColor('#666666')

      Slider({
        value: this.getProgressValue(),
        min: 0,
        max: 1,
        step: 0.001,
        style: SliderStyle.OutSet
      })
        .blockColor('#1677ff')
        .trackColor('#d9dde3')
        .selectedColor('#1677ff')
        .onChange((value: number) => {
          this.sliderValue = value;
        })
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            const targetMs = Math.floor(this.sliderValue * this.durationMs);
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
