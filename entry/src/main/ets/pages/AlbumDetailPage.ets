import common from '@ohos.app.ability.common';
import { router } from '@kit.ArkUI';
import { AlbumApi } from '../features/music/album/data/api/AlbumApi';
import { AlbumInfo } from '../features/music/album/domain/model/AlbumModels';
import { Song } from '../features/music/domain/model/Song';
import { SongList, SongListCallbacks } from '../features/music/ui/component/SongList';
import { PlayerEngine } from '../features/music/service/PlayerEngine';

@Component
export struct AlbumDetailPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @Prop albumId: number = 0;

  @State loading: boolean = true;
  @State errorText: string = '';
  @State album: AlbumInfo | null = null;
  @State songs: Song[] = [];
  @State currentTab: number = 1;
  private tabsController: TabsController = new TabsController();

  private albumApi?: AlbumApi;
  private engine: PlayerEngine = PlayerEngine.getInstance();

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    this.albumApi = new AlbumApi(context);
    this.loadAlbumDetail();
  }

  private async loadAlbumDetail(): Promise<void> {
    if (this.albumApi === undefined) {
      return;
    }

    this.loading = true;
    this.errorText = '';

    try {
      const response = await this.albumApi.getAlbumDetail(this.albumId);
      this.album = response.album;
      this.songs = response.songs;
    } catch (error) {
      this.errorText = `专辑信息加载失败：${(error as Error).message}`;
    } finally {
      this.loading = false;
    }
  }

  private async playSong(song: Song, index: number): Promise<void> {
    this.engine.setQueue(this.songs, index);
    router.pushUrl({ url: 'pages/MusicPlayerPage', params: { songId: song.id } });
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
          AppStorage.setOrCreate<number>('mainNavDepth', this.pathStack.size());
        })

        Text(this.album ? this.album.name : '专辑详情')
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
      } else if (this.album) {
        Column() {
          // Fixed album header
          Row({ space: 16 }) {
            Image(this.album.picUrl)
              .width(120)
              .height(120)
              .borderRadius(12)
              .objectFit(ImageFit.Cover)
              .alt($r('app.media.startIcon'))
              .shadow({ radius: 12, color: 'rgba(0,0,0,0.12)', offsetX: 0, offsetY: 4 })

            Column({ space: 8 }) {
              Text(this.album.name)
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Text(this.album.artist ? this.album.artist.name : '未知歌手')
                .fontSize(14)
                .fontColor($r('app.color.text_brand'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .onClick(() => {
                  if (this.album && this.album.artist) {
                    this.pathStack.pushPath({ name: 'ArtistDetailPage', param: this.album.artist.id });
                    AppStorage.setOrCreate<number>('mainNavDepth', this.pathStack.size());
                  }
                })

              Text(`${this.album.size} 首`)
                .fontSize(13)
                .fontColor($r('app.color.text_quaternary'))
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')

          // Tab bar
          Row({ space: 24 }) {
            this.tabButton('简介', 0);
            this.tabButton('歌曲列表', 1);
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 0 })

          // Tab content
          Tabs({ index: this.currentTab, controller: this.tabsController }) {
            TabContent() {
              // 简介 tab
              if (this.album.description.length === 0) {
                Column() {
                  Text('暂无简介')
                    .fontSize(14)
                    .fontColor($r('app.color.text_quaternary'))
                }
                .width('100%')
                .height('100%')
                .justifyContent(FlexAlign.Center)
              } else {
                Scroll() {
                  Column() {
                    Text(this.album.description)
                      .fontSize(14)
                      .fontColor($r('app.color.text_secondary'))
                      .lineHeight(24)
                      .width('100%')
                    Blank().height(80);
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 12, bottom: 16 })
                }
                .width('100%')
                .layoutWeight(1)
              }
            }

            TabContent() {
              // 歌曲列表 tab
              if (this.songs.length === 0) {
                Column() {
                  Text('暂无歌曲信息')
                    .fontSize(14)
                    .fontColor($r('app.color.text_quaternary'))
                }
                .width('100%')
                .height('100%')
                .justifyContent(FlexAlign.Center)
              } else {
                Scroll() {
                  Column() {
                    Row({ space: 8 }) {
                      Blank()
                        .width(3)
                        .height(16)
                        .backgroundColor($r('app.color.text_brand'))
                        .borderRadius(2)
                      Text('歌曲列表')
                        .fontSize(16)
                        .fontWeight(FontWeight.Medium)
                        .fontColor($r('app.color.text_primary'))
                    }
                    .width('100%')

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
          }
          .barHeight(0)
          .layoutWeight(1)
          .onChange((index: number) => {
            this.currentTab = index;
          })
        }
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 12, bottom: 0 })
      } else {
        Column({ space: 12 }) {
          Text(this.errorText)
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.Center)
          Button('重试')
            .onClick(() => {
              this.loadAlbumDetail();
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