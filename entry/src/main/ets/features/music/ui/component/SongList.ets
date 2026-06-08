import { Song } from '../../domain/model/Song';
import { SongArtist } from '../../domain/model/SongModels';

export interface SongListCallbacks {
  onSongClick: (song: Song, index: number) => void;
}

export class SongListDataSource implements IDataSource {
  private listeners: DataChangeListener[] = [];
  private data: Song[] = [];

  totalCount(): number {
    return this.data.length;
  }

  getData(index: number): Song {
    return this.data[index];
  }

  setData(data: Song[]): void {
    this.data = data;
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataReloaded();
    });
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }
}

@Component
export struct SongList {
  @Prop @Watch('onSongsChanged') songs: Song[] = [];
  @Prop callbacks: SongListCallbacks;
  @StorageLink('selectedSongId') private selectedSongId: number = 0;

  private dataSource: SongListDataSource = new SongListDataSource();

  aboutToAppear(): void {
    this.dataSource.setData(this.songs);
  }

  onSongsChanged(): void {
    this.dataSource.setData(this.songs);
  }

  private getArtistNames(song: Song): string {
    if (song.ar.length === 0) {
      return '未知歌手';
    }
    return song.ar.map((artist: SongArtist) => artist.name).join(' / ');
  }

  private getDurationText(song: Song): string {
    const totalSeconds = Math.floor(song.dt / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    const secondText = seconds < 10 ? `0${seconds}` : `${seconds}`;
    return `${minutes}:${secondText}`;
  }

  @Builder
  private songRow(song: Song, index: number) {
    Row({ space: 12 }) {
      Text(`${index + 1}`)
        .fontSize(13)
        .fontColor(this.selectedSongId === song.id ? $r('app.color.text_brand') : $r('app.color.text_tertiary'))
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
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${this.getArtistNames(song)} - ${song.al.name}`)
          .fontSize(12)
          .fontColor($r('app.color.text_quaternary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text(this.getDurationText(song))
        .fontSize(12)
        .fontColor($r('app.color.text_tertiary'))
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .onClick(() => {
      this.callbacks.onSongClick(song, index);
    })
  }

  build() {
    List({ space: 2 }) {
      LazyForEach(this.dataSource, (item: Song, index: number) => {
        ListItem() {
          this.songRow(item, index);
        }
      }, (item: Song) => `${item.id}`)
    }
    .width('100%')
    .layoutWeight(1)
  }
}
