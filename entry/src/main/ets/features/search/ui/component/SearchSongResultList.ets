import { promptAction, router } from '@kit.ArkUI';
import { Song } from '../../../music/domain/model/Song';
import { PlayerEngine } from '../../../music/service/PlayerEngine';

@Component
export struct SearchSongResultList {
  @Prop songs: Song[] = [];
  @Prop loadingMore: boolean = false;
  @Prop hasMore: boolean = false;
  @Prop isLoading: boolean = false;
  @Prop errorMessage: string = '';
  onLoadMore: () => void = () => {};

  @StorageLink('selectedSongId') private selectedSongId: number = 0;
  private engine: PlayerEngine = PlayerEngine.getInstance();

  private getArtistNames(song: Song): string {
    if (song.ar.length === 0) {
      return '未知歌手';
    }
    return song.ar.map((artist) => artist.name).join(' / ');
  }

  private getDurationText(song: Song): string {
    const totalSeconds = Math.floor(song.dt / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    const secondText = seconds < 10 ? `0${seconds}` : `${seconds}`;
    return `${minutes}:${secondText}`;
  }

  private async playSong(song: Song, index: number): Promise<void> {
    try {
      await this.engine.setQueue(this.songs, index);
      router.pushUrl({
        url: 'pages/MusicPlayerPage',
        params: {
          songId: song.id
        }
      });
    } catch (error) {
      promptAction.showToast({ message: '歌曲播放失败' });
    }
  }

  @Builder
  private songRow(song: Song, index: number) {
    Row({ space: 12 }) {
      Text(`${index + 1}`)
        .fontSize(13)
        .fontColor(this.selectedSongId === song.id ? '#1677ff' : '#999999')
        .width(24)
        .textAlign(TextAlign.Center)

      Column({ space: 4 }) {
        Text(song.name)
          .fontSize(15)
          .fontWeight(this.selectedSongId === song.id ? FontWeight.Medium : FontWeight.Regular)
          .fontColor('#1f2937')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${this.getArtistNames(song)} - ${song.al.name}`)
          .fontSize(12)
          .fontColor('#777777')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text(this.getDurationText(song))
        .fontSize(12)
        .fontColor('#999999')
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .onClick(() => {
      void this.playSong(song, index);
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
          .fontColor('#999999')
      }
      .width('100%')
      .height(48)
      .justifyContent(FlexAlign.Center)
    } else if (this.hasMore) {
      Button('加载更多')
        .width('100%')
        .height(40)
        .backgroundColor('#f2f3f5')
        .fontColor('#1677ff')
        .onClick(() => {
          this.onLoadMore();
        })
    } else {
      Text('没有更多了')
        .fontSize(12)
        .fontColor('#999999')
        .width('100%')
        .height(48)
        .textAlign(TextAlign.Center)
    }
  }

  build() {
    if (this.isLoading) {
      Column({ space: 8 }) {
        LoadingProgress()
          .width(28)
          .height(28)
        Text('搜索中...')
          .fontSize(13)
          .fontColor('#666666')
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else if (this.errorMessage.length > 0) {
      Column({ space: 8 }) {
        Text(this.errorMessage)
          .fontSize(13)
          .fontColor('#d94841')
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else if (this.songs.length === 0) {
      Column() {
        Text('暂无搜索结果')
          .fontSize(13)
          .fontColor('#666666')
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else {
      List({ space: 2 }) {
        ForEach(this.songs, (song: Song, index: number) => {
          ListItem() {
            this.songRow(song, index);
          }
        }, (song: Song) => `${song.id}`)
        ListItem() {
          this.footerArea();
        }
      }
      .width('100%')
      .layoutWeight(1)
      .listDirection(Axis.Vertical)
    }
  }
}
