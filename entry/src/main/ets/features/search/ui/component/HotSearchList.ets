import common from '@ohos.app.ability.common';
import { SearchHotDetailItem } from '../../domain/model/SearchHotModels';
import { SearchHotApi } from '../../data/api/SearchHotApi';

@Component
export struct HotSearchList {
  @State private items: SearchHotDetailItem[] = [];
  @State private loading: boolean = true;
  @State private errorMessage: string = '';

  onItemClick: (searchWord: string) => void = () => {};

  private api?: SearchHotApi;

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    this.api = new SearchHotApi(context);
    this.loadHotDetail();
  }

  private async loadHotDetail(): Promise<void> {
    if (this.api === undefined) {
      return;
    }

    this.loading = true;
    this.errorMessage = '';

    try {
      const response = await this.api.getHotDetail();
      this.items = response.data;
    } catch (error) {
      const message = (error as Error).message;
      this.errorMessage = message.length > 0 ? message : '热搜加载失败';
    } finally {
      this.loading = false;
    }
  }

  private formatScore(score: number): string {
    if (score >= 10000) {
      return `${Math.floor(score / 10000)}万`;
    }
    return `${score}`;
  }

  @Builder
  private itemRow(item: SearchHotDetailItem, index: number) {
    Row({ space: 12 }) {
      Text(`${index + 1}`)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(index < 3 ? '#d94841' : '#666666')
        .width(24)
        .textAlign(TextAlign.Center)

      Column({ space: 2 }) {
        Row({ space: 6 }) {
          Text(item.searchWord ?? '')
            .fontSize(15)
            .fontColor('#1f2937')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if ((item.iconUrl ?? '').length > 0) {
            Image(item.iconUrl ?? '')
              .width(14)
              .height(14)
              .objectFit(ImageFit.Cover)
          }
        }
        .width('100%')

        if ((item.content ?? '').length > 0) {
          Text(item.content ?? '')
            .fontSize(11)
            .fontColor('#999999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (item.score > 0) {
        Text(this.formatScore(item.score))
          .fontSize(12)
          .fontColor('#999999')
      }
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .onClick(() => {
      this.onItemClick(item.searchWord ?? '');
    })
  }

  build() {
    if (this.loading) {
      Column({ space: 8 }) {
        LoadingProgress()
          .width(28)
          .height(28)
        Text('热搜加载中...')
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
        Button('重试')
          .onClick(() => {
            this.loadHotDetail();
          })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else if (this.items.length === 0) {
      Text('暂无热搜')
        .fontSize(13)
        .fontColor('#666666')
        .width('100%')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
    } else {
      List({ space: 0 }) {
        ForEach(this.items, (item: SearchHotDetailItem, index: number) => {
          ListItem() {
            this.itemRow(item, index);
          }
        }, (item: SearchHotDetailItem) => `${item.searchWord ?? ''}-${item.score}`)
      }
      .width('100%')
      .layoutWeight(1)
      .listDirection(Axis.Vertical)
      .divider({ strokeWidth: 0.5, color: '#f0f0f0' })
    }
  }
}
