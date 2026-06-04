import { PlayerEngine } from '../../service/PlayerEngine';
import { router } from '@kit.ArkUI';

@Component
export struct MiniPlayerBar {
  @StorageLink('miniPlayerVisible') visible: boolean = false;
  @StorageLink('miniPlayerTitle') songTitle: string = '未选择歌曲';
  @StorageLink('miniPlayerArtist') artistText: string = '';
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

  build() {
    if (this.visible) {
      Column({ space: 6 }) {
        Row({ space: 12 }) {
          Column({ space: 2 }) {
            Text(this.songTitle)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(this.artistText.length > 0 ? this.artistText : '未知歌手')
              .fontSize(12)
              .fontColor('#666666')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .onClick(() => {
            if (this.songId <= 0) {
              return;
            }
            router.pushUrl({
              url: 'pages/MusicPlayerPage',
              params: {
                songId: this.songId
              }
            });
          })

          Button() {
            Image(this.playing ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
              .width(16)
              .height(16)
          }
            .type(ButtonType.Circle)
            .width(36)
            .height(36)
            .backgroundColor('#e5e7eb')
            .onClick(() => {
              this.engine.togglePlay().catch((error: Error) => {
                console.error(`toggle play failed: ${error.message}`);
              });
            })
        }

        Progress({ value: this.getProgressValue(), total: 1, style: ProgressStyle.Linear })
          .height(3)
          .color('#1677ff')
          .backgroundColor('#d9dde3')
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor('#f2f3f5')
      .borderRadius(12)
    }
  }
}
