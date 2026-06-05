import { DailyRecommendSong, RecommendArtist } from '../../domain/model/DailyRecommendModels';

export interface DailyRecommendSongListCallbacks {
  onSongClick: (song: DailyRecommendSong) => void;
}

@Component
export struct DailyRecommendSongList {
  @Prop songs: DailyRecommendSong[] = [];
  @Prop callbacks: DailyRecommendSongListCallbacks;
  @StorageLink('selectedSongId') private selectedSongId: number = 0;

  private getArtistNames(song: DailyRecommendSong): string {
    if (song.ar.length === 0) {
      return '未知歌手';
    }
    return song.ar.map((artist: RecommendArtist) => artist.name).join(' / ');
  }

  private getDurationText(song: DailyRecommendSong): string {
    const totalSeconds = Math.floor(song.dt / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    const secondText = seconds < 10 ? `0${seconds}` : `${seconds}`;
    return `${minutes}:${secondText}`;
  }

  @Builder
  private songRow(song: DailyRecommendSong, index: number) {
    Row({ space: 12 }) {
      Text(`${index + 1}`)
        .fontSize(13)
        .fontColor(this.selectedSongId === song.id ? '#1677ff' : '#999999')
        .width(24)
        .textAlign(TextAlign.Center)

      Image(song.al.picUrl)
        .width(48)
        .height(48)
        .borderRadius(6)
        .objectFit(ImageFit.Cover)

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
      this.callbacks.onSongClick(song);
    })
  }

  build() {
    List({ space: 2 }) {
      ForEach(this.songs, (item: DailyRecommendSong, index: number) => {
        ListItem() {
          this.songRow(item, index);
        }
      }, (item: DailyRecommendSong) => `${item.id}`)
    }
    .width('100%')
    .layoutWeight(1)
  }
}
