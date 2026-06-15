import { Song } from '../../domain/model/Song';
import { SongArtist } from '../../domain/model/SongModels';

export interface SongListCallbacks {
  onSongClick: (song: Song, index: number) => void;
  onPlayNextClick?: (song: Song, index: number) => void;
  onDeleteClick?: (song: Song, index: number) => void;
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
  @State private showActionSheet: boolean = false;
  @State private actionSong: Song | null = null;
  @State private actionIndex: number = -1;

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

  private openActionSheet(song: Song, index: number): void {
    this.actionSong = song;
    this.actionIndex = index;
    this.showActionSheet = true;
  }

  private closeActionSheet(): void {
    this.showActionSheet = false;
  }

  private triggerPlayNext(): void {
    if (this.actionSong === null || this.actionIndex < 0) {
      return;
    }
    if (this.callbacks.onPlayNextClick !== undefined) {
      this.callbacks.onPlayNextClick(this.actionSong, this.actionIndex);
    }
    this.closeActionSheet();
  }

  private triggerDelete(): void {
    if (this.actionSong === null || this.actionIndex < 0) {
      return;
    }
    if (this.callbacks.onDeleteClick !== undefined) {
      this.callbacks.onDeleteClick(this.actionSong, this.actionIndex);
    }
    this.closeActionSheet();
  }

  @Builder
  private actionSheet() {
    Column({ space: 10 }) {
      Button() {
        Row({ space: 10 }) {
          Image($r('app.media.ic_playlist_add'))
            .width(18)
            .height(18)
            .fillColor($r('app.color.text_primary'))
          Text('添加到下一首播放')
            .fontSize(15)
            .fontColor($r('app.color.text_primary'))
        }
      }
        .width('100%')
        .height(46)
        .backgroundColor($r('app.color.surface_info'))
        .onClick(() => {
          this.triggerPlayNext();
        })

      if (this.callbacks.onDeleteClick !== undefined) {
        Button() {
          Row({ space: 10 }) {
            Image($r('app.media.ic_delete'))
              .width(18)
              .height(18)
              .fillColor($r('app.color.text_danger'))
            Text('删除')
              .fontSize(15)
              .fontColor($r('app.color.text_danger'))
          }
        }
          .width('100%')
          .height(46)
          .backgroundColor($r('app.color.surface_info'))
          .onClick(() => {
            this.triggerDelete();
          })
      }

      Button('取消')
        .width('100%')
        .height(44)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .backgroundColor($r('app.color.surface_subtle'))
        .onClick(() => {
          this.closeActionSheet();
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 24 })
    .backgroundColor(Color.White)
  }

  @Builder
  private songRow(song: Song, index: number) {
    Column() {
      Row({ space: 12 }) {
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
              .fontColor(this.selectedSongId === song.id ? $r('app.color.text_brand') : $r('app.color.text_primary'))
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
        }
        .layoutWeight(1)
        .onClick(() => {
          this.callbacks.onSongClick(song, index);
        })

        Text(this.getDurationText(song))
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
          .width(38)
          .textAlign(TextAlign.End)

        Button() {
          Image($r('app.media.ic_more_vert'))
            .width(20)
            .height(20)
            .fillColor($r('app.color.text_tertiary'))
        }
          .type(ButtonType.Circle)
          .width(40)
          .height(40)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.openActionSheet(song, index);
          })
      }
      .width('100%')
      .padding({ top: 10, bottom: 10 })

      if (index < this.songs.length - 1) {
        Divider()
          .color($r('app.color.divider_subtle'))
          .width('100%')
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      List() {
        LazyForEach(this.dataSource, (item: Song, index: number) => {
          ListItem() {
            this.songRow(item, index);
          }
        }, (item: Song) => `${item.id}`)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .layoutWeight(1)
    .bindSheet(this.showActionSheet, this.actionSheet(), {
      height: 220,
      showClose: false,
      dragBar: true,
      onDisappear: () => {
        this.showActionSheet = false;
      }
    })
  }
}
