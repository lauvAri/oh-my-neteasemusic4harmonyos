import { PlayerEngine } from '../../service/PlayerEngine';
import { router } from '@kit.ArkUI';

@Component
export struct MiniPlayerBar {
  @StorageLink('miniPlayerVisible') visible: boolean = false;
  @StorageLink('miniPlayerTitle') songTitle: string = '未选择歌曲';
  @StorageLink('miniPlayerArtist') artistText: string = '';
  @StorageLink('miniPlayerCover') coverUrl: string = '';
  @StorageLink('miniPlayerPlaying') playing: boolean = false;
  @StorageLink('selectedSongId') songId: number = 0;
  @StorageLink('playerCurrentMs') currentMs: number = 0;
  @StorageLink('playerDurationMs') durationMs: number = 0;

  private engine: PlayerEngine = PlayerEngine.getInstance();

  private getProgressValue(): number {
    if (this.durationMs <= 0) {
      return 0;
    }
    return this.currentMs / this.durationMs;
  }

  @Builder
  private playerBody() {
    Column({ space: 6 }) {
      Row({ space: 12 }) {
        if (this.coverUrl.length > 0) {
          Image(this.coverUrl)
            .width(44)
            .height(44)
            .borderRadius(6)
            .objectFit(ImageFit.Cover)
            .onClick(() => {
              this.openPlayerPage();
            })
        } else {
          Stack() {
            Text('♪')
              .fontSize(20)
              .fontColor($r('app.color.text_muted_placeholder'))
          }
          .width(44)
          .height(44)
          .backgroundColor('#22000000')
          .borderRadius(6)
          .onClick(() => {
            this.openPlayerPage();
          })
        }

        Column({ space: 2 }) {
          Text(this.songTitle)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.artistText.length > 0 ? this.artistText : '未知歌手')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .onClick(() => {
          this.openPlayerPage();
        })

        Button() {
          Image(this.playing ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
            .width(16)
            .height(16)
            .fillColor($r('app.color.icon_primary'))
        }
          .type(ButtonType.Circle)
          .width(36)
          .height(36)
          .backgroundColor('#22000000')
          .onClick(() => {
            this.engine.togglePlay().catch((error: Error) => {
              console.error(`toggle play failed: ${error.message}`);
            });
          })
      }

        Progress({
          value: Math.round(this.getProgressValue() * 100),
          total: 100,
          style: ProgressStyle.Linear
        })
          .width('100%')
          .height(3)
          .color($r('app.color.text_brand'))
          .backgroundColor($r('app.color.progress_track_translucent'))
    }
    .width('100%')
  }

  build() {
    if (this.visible) {
      this.playerBody();
    } else {
      Row() {}
    }
  }

  private openPlayerPage(): void {
    if (this.songId <= 0) {
      return;
    }
    router.pushUrl({
      url: 'pages/MusicPlayerPage',
      params: {
        songId: this.songId
      }
    });
  }
}
