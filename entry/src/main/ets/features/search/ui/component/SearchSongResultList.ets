import { promptAction, router } from '@kit.ArkUI';
import { Song } from '../../../music/domain/model/Song';
import { PlayerEngine } from '../../../music/service/PlayerEngine';
import { getSubpageBottomPaddingVp } from '../../../../common/ui/PageLayout';

@Component
export struct SearchSongResultList {
  @StorageLink('miniPlayerVisible') private miniPlayerVisible: boolean = false;
  @Prop songs: Song[] = [];
  @Prop loadingMore: boolean = false;
  @Prop hasMore: boolean = false;
  @Prop isLoading: boolean = false;
  @Prop errorMessage: string = '';
  onLoadMore: () => void = () => {};
  @Consume('pathStack') pathStack: NavPathStack;

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
        .fontColor(this.selectedSongId === song.id ? $r('app.color.text_brand') : $r('app.color.text_tertiary'))
        .width(24)
        .textAlign(TextAlign.Center)

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
          .fontColor($r('app.color.text_tertiary'))
      }
      .width('100%')
      .height(48)
      .justifyContent(FlexAlign.Center)
    } else if (this.hasMore) {
      Button('加载更多')
        .width('100%')
        .height(40)
        .backgroundColor($r('app.color.surface_input'))
        .fontColor($r('app.color.text_brand'))
        .onClick(() => {
          this.onLoadMore();
        })
    } else {
      Text('没有更多了')
        .fontSize(12)
        .fontColor($r('app.color.text_tertiary'))
        .width('100%')
        .height(48)
        .textAlign(TextAlign.Center)
    }
  }

  private getBottomPadding(): number {
    return getSubpageBottomPaddingVp(this.miniPlayerVisible);
  }

  build() {
    if (this.isLoading) {
      Column({ space: 8 }) {
        LoadingProgress()
          .width(28)
          .height(28)
        Text('搜索中...')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .padding({ bottom: this.getBottomPadding() })
    } else if (this.errorMessage.length > 0) {
      Column({ space: 8 }) {
        Text(this.errorMessage)
          .fontSize(13)
          .fontColor($r('app.color.text_danger'))
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .padding({ bottom: this.getBottomPadding() })
    } else if (this.songs.length === 0) {
      Column() {
        Text('暂无搜索结果')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .padding({ bottom: this.getBottomPadding() })
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
        ListItem() {
          Row() {
            Blank().height(this.getBottomPadding());
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
      .listDirection(Axis.Vertical)
    }
  }
}
