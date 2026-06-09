import common from '@ohos.app.ability.common';
import { router } from '@kit.ArkUI';
import { ArtistApi } from '../features/music/artist/data/api/ArtistApi';
import { ArtistInfo, ArtistAlbumItem } from '../features/music/artist/domain/model/ArtistModels';
import { Song } from '../features/music/domain/model/Song';
import { SongList, SongListCallbacks } from '../features/music/ui/component/SongList';
import { PlayerEngine } from '../features/music/service/PlayerEngine';
import { ExpandableText } from '../common/ui/ExpandableText';

@Component
export struct ArtistDetailPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @Prop artistId: number = 0;

  @State loading: boolean = true;
  @State errorText: string = '';
  @State artist: ArtistInfo | null = null;
  @State songs: Song[] = [];
  @State albums: ArtistAlbumItem[] = [];
  @State songsError: string = '';
  @State albumsError: string = '';
  @State currentTab: number = 0;

  private artistApi?: ArtistApi;
  private engine: PlayerEngine = PlayerEngine.getInstance();
  private tabsController: TabsController = new TabsController();

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    this.artistApi = new ArtistApi(context);
    this.loadArtistDetail();
  }

  private async loadArtistDetail(): Promise<void> {
    if (this.artistApi === undefined) {
      return;
    }

    this.loading = true;
    this.errorText = '';

    try {
      const detailResponse = await this.artistApi.getArtistDetail(this.artistId);
      this.artist = detailResponse.data.artist;

      const results = await Promise.allSettled([
        this.artistApi.getArtistSongs(this.artistId),
        this.artistApi.getArtistAlbums(this.artistId)
      ]);

      if (results[0].status === 'fulfilled') {
        this.songs = results[0].value.songs;
        this.songsError = '';
      } else {
        this.songsError = '歌曲加载失败';
      }
      if (results[1].status === 'fulfilled') {
        this.albums = results[1].value.hotAlbums;
        this.albumsError = '';
      } else {
        this.albumsError = '专辑加载失败';
      }
    } catch (error) {
      this.errorText = `歌手信息加载失败：${(error as Error).message}`;
    } finally {
      this.loading = false;
    }
  }

  private getArtistImageUrl(): string {
    if (this.artist === null) {
      return '';
    }
    if (this.artist.avatar.length > 0) {
      return this.artist.avatar;
    }
    if (this.artist.cover.length > 0) {
      return this.artist.cover;
    }
    return '';
  }

  private async playSong(song: Song, index: number): Promise<void> {
    this.engine.setQueue(this.songs, index);
    router.pushUrl({ url: 'pages/MusicPlayerPage', params: { songId: song.id } });
  }

  private formatCount(count: number): string {
    if (count >= 100000000) {
      return `${(count / 100000000).toFixed(1)}亿`;
    }
    if (count >= 10000) {
      return `${(count / 10000).toFixed(1)}万`;
    }
    return `${count}`;
  }

  private formatPublishTime(timestamp: number): string {
    if (timestamp <= 0) {
      return '';
    }
    const date = new Date(timestamp);
    return `${date.getFullYear()}`;
  }

  @Builder
  private tabButton(title: string, index: number) {
    Text(title)
      .fontSize(15)
      .fontWeight(this.currentTab === index ? FontWeight.Medium : FontWeight.Regular)
      .fontColor(this.currentTab === index ? $r('app.color.text_brand') : $r('app.color.text_secondary'))
      .padding({ bottom: 8 })
      .borderWidth({ bottom: 2 })
      .borderColor(this.currentTab === index ? $r('app.color.text_brand') : Color.Transparent)
      .onClick(() => {
        this.currentTab = index;
        this.tabsController.changeIndex(index);
      })
  }

  build() {
    Column() {
      Row() {
        Button() {
          Image($r('app.media.ic_arrow_back'))
            .width(20)
            .height(20)
            .fillColor($r('app.color.text_primary'))
        }
        .type(ButtonType.Circle)
        .width(36)
        .height(36)
        .backgroundColor($r('app.color.surface_info'))
        .onClick(() => {
          this.pathStack.pop();
        })

        Text(this.artist ? this.artist.name : '歌手详情')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .margin({ left: 12 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })

      if (this.loading) {
        Column({ space: 12 }) {
          LoadingProgress()
            .width(44)
            .height(44)
          Text('正在加载...')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.artist) {
        Column() {
          // Artist header
          Row({ space: 16 }) {
            Image(this.getArtistImageUrl())
              .width(88)
              .height(88)
              .borderRadius(44)
              .objectFit(ImageFit.Cover)
              .alt($r('app.media.startIcon'))
              .shadow({ radius: 8, color: 'rgba(0,0,0,0.10)', offsetX: 0, offsetY: 2 })

            Column({ space: 6 }) {
              Text(this.artist.name)
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Row({ space: 16 }) {
                Text(`${this.formatCount(this.artist.musicSize)} 首歌曲`)
                  .fontSize(13)
                  .fontColor($r('app.color.text_secondary'))
                Text(`${this.formatCount(this.artist.albumSize)} 张专辑`)
                  .fontSize(13)
                  .fontColor($r('app.color.text_secondary'))
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 4, bottom: 4 })

          // Expandable description
          if (this.artist.briefDesc.length > 0) {
            ExpandableText({
              content: this.artist.briefDesc,
              maxLines: 2,
              fontSize: 13,
              fontColor: $r('app.color.text_secondary'),
              brandColor: $r('app.color.text_brand'),
              constraintWidth: 311
            })
            .width('100%')
            .padding({ left: 16, right: 16, top: 4, bottom: 8 })
          }

          // Tab bar
          Row({ space: 32 }) {
            this.tabButton('热门歌曲', 0);
            this.tabButton('专辑', 1);
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 0 })

          // Tab content
          Tabs({ index: this.currentTab, controller: this.tabsController }) {
            TabContent() {
              if (this.songs.length === 0) {
                Column() {
                  Text(this.songsError.length > 0 ? this.songsError : '暂无歌曲信息')
                    .fontSize(14)
                    .fontColor(this.songsError.length > 0 ? '#FF5252' : $r('app.color.text_quaternary'))
                }
                .width('100%')
                .height('100%')
                .justifyContent(FlexAlign.Center)
              } else {
                Scroll() {
                  Column() {
                    SongList({
                      songs: this.songs,
                      callbacks: {
                        onSongClick: (song: Song, index: number) => {
                          this.playSong(song, index);
                        }
                      } as SongListCallbacks
                    })
                    Blank().height(80);
                  }
                  .width('100%')
                }
                .width('100%')
                .layoutWeight(1)
              }
            }

            TabContent() {
              if (this.albums.length === 0) {
                Column() {
                  Text(this.albumsError.length > 0 ? this.albumsError : '暂无专辑信息')
                    .fontSize(14)
                    .fontColor(this.albumsError.length > 0 ? '#FF5252' : $r('app.color.text_quaternary'))
                }
                .width('100%')
                .height('100%')
                .justifyContent(FlexAlign.Center)
              } else {
                Scroll() {
                  Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                    ForEach(this.albums, (item: ArtistAlbumItem) => {
                      Column({ space: 6 }) {
                        Image(item.picUrl)
                          .width(100)
                          .height(100)
                          .borderRadius(8)
                          .objectFit(ImageFit.Cover)
                          .alt($r('app.media.startIcon'))
                        Text(item.name)
                          .fontSize(12)
                          .fontColor($r('app.color.text_primary'))
                          .maxLines(2)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .width(100)
                        Text(this.formatPublishTime(item.publishTime))
                          .fontSize(11)
                          .fontColor($r('app.color.text_quaternary'))
                          .width(100)
                      }
                      .width('30%')
                      .margin({ right: '3.33%', bottom: 16 })
                      .onClick(() => {
                        this.pathStack.pushPath({ name: 'AlbumDetailPage', param: item.id });
                        AppStorage.setOrCreate<number>('mainNavDepth', this.pathStack.size());
                      })
                    }, (item: ArtistAlbumItem) => `${item.id}`)
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 8, bottom: 16 })
                }
                .width('100%')
                .layoutWeight(1)
              }
            }
          }
          .barHeight(0)
          .layoutWeight(1)
          .onChange((index: number) => {
            this.currentTab = index;
          })
        }
        .layoutWeight(1)
      } else {
        Column({ space: 12 }) {
          Text(this.errorText)
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.Center)
          Button('重试')
            .onClick(() => {
              this.loadArtistDetail();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }
}