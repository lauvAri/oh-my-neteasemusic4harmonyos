import common from '@ohos.app.ability.common';
import { router, promptAction } from '@kit.ArkUI';
import { Toplist, ArtistToplist } from '../../domain/model/ToplistModels';
import { ToplistApi } from '../../data/api/ToplistApi';

interface ToplistCardItem {
  key: string;
  name: string;
  coverUrl: string;
  updateFrequency: string;
  kind: 'playlist' | 'artist';
  playlistId: number;
}

@Component
export struct ToplistRow {
  @State private items: ToplistCardItem[] = [];
  @State private loading: boolean = true;
  @State private errorMessage: string = '';

  private api?: ToplistApi;

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    this.api = new ToplistApi(context);
    this.loadToplists();
  }

  private async loadToplists(): Promise<void> {
    if (this.api === undefined) {
      return;
    }

    this.loading = true;
    this.errorMessage = '';

    try {
      const response = await this.api.getToplist();
      this.items = this.buildItems(response.list, response.artistToplist);
    } catch (error) {
      const message = (error as Error).message;
      this.errorMessage = message.length > 0 ? message : '排行榜加载失败';
    } finally {
      this.loading = false;
    }
  }

  private buildItems(list: Toplist[], artistToplist: ArtistToplist): ToplistCardItem[] {
    const result: ToplistCardItem[] = [];
    for (let i = 0; i < list.length; i++) {
      const item = list[i];
      result.push({
        key: `toplist-${item.id}`,
        name: item.name,
        coverUrl: item.coverImgUrl,
        updateFrequency: item.updateFrequency,
        kind: 'playlist',
        playlistId: item.id
      });
    }
    if (artistToplist.coverUrl.length > 0 && artistToplist.name.length > 0) {
      result.push({
        key: 'artist-toplist',
        name: artistToplist.name,
        coverUrl: artistToplist.coverUrl,
        updateFrequency: artistToplist.updateFrequency,
        kind: 'artist',
        playlistId: 0
      });
    }
    return result;
  }

  private handleItemClick(item: ToplistCardItem): void {
    if (item.kind === 'playlist') {
      router.pushUrl({
        url: 'pages/PlaylistDetailPage',
        params: {
          playlistId: item.playlistId
        }
      });
    } else {
      promptAction.showToast({ message: '歌手榜暂未支持' });
    }
  }

  @Builder
  private toplistCard(item: ToplistCardItem) {
    Column({ space: 6 }) {
      Stack({ alignContent: Alignment.BottomStart }) {
        Image(item.coverUrl)
          .width(120)
          .height(120)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)

        if (item.updateFrequency.length > 0) {
          Text(item.updateFrequency)
            .fontSize(11)
            .fontColor(Color.White)
            .backgroundColor('#66000000')
            .padding({ left: 4, right: 4, top: 2, bottom: 2 })
            .borderRadius(4)
            .margin(6)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .constraintSize({ maxWidth: 100 })
        }
      }
      .width(120)
      .height(120)

      Text(item.name)
        .fontSize(13)
        .fontColor('#1f2937')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
    }
    .width(120)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      this.handleItemClick(item);
    })
  }

  build() {
    Column({ space: 10 }) {
      Text('排行榜')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1f2937')
        .width('100%')

      if (this.loading) {
        Column({ space: 8 }) {
          LoadingProgress()
            .width(28)
            .height(28)
          Text('排行榜加载中...')
            .fontSize(13)
            .fontColor('#666666')
        }
        .width('100%')
        .height(140)
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMessage.length > 0) {
        Column({ space: 8 }) {
          Text(this.errorMessage)
            .fontSize(13)
            .fontColor('#d94841')
          Button('重试')
            .onClick(() => {
              this.loadToplists();
            })
        }
        .width('100%')
        .height(140)
        .justifyContent(FlexAlign.Center)
      } else if (this.items.length === 0) {
        Text('暂无排行榜')
          .fontSize(13)
          .fontColor('#666666')
          .width('100%')
          .height(140)
          .textAlign(TextAlign.Center)
      } else {
        Scroll() {
          Row({ space: 12 }) {
            ForEach(this.items, (item: ToplistCardItem) => {
              this.toplistCard(item);
            }, (item: ToplistCardItem) => item.key)
          }
          .padding({ left: 0, right: 4 })
        }
        .width('100%')
        .scrollable(ScrollDirection.Horizontal)
      }
    }
    .width('100%')
  }
}
