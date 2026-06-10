import { HomeBanner } from '../features/banner/ui/component/HomeBanner';
import { RecommendPlaylistRow } from '../features/music/playlist/ui/component/RecommendPlaylistRow';
import { ToplistRow } from '../features/music/playlist/ui/component/ToplistRow';
import { TAB_PAGE_BOTTOM_PADDING_VP } from '../common/ui/PageLayout';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;

@Component
export struct HomePage {
  @Consume('pathStack') pathStack: NavPathStack;
  build() {
    Scroll() {
      Column({ space: 16 }) {
        Row({ space: 12 }) {
          Text('首页')
            .fontSize(26)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)

          Button() {
            Image($r('app.media.ic_search'))
              .width(18)
              .height(18)
              .fillColor($r('app.color.icon_primary'))
          }
          .type(ButtonType.Circle)
          .width(36)
          .height(36)
          .backgroundColor($r('app.color.surface_subtle'))
          .onClick(() => {
            hilog.info(DOMAIN, 'NavRoute', 'pushPath: SearchPage');
            this.pathStack.pushPath({ name: 'SearchPage' });
            AppStorage.setOrCreate<number>('mainNavDepth', this.pathStack.size());
          })
        }
        .width('100%')

        HomeBanner();

        RecommendPlaylistRow();

        Row() {
          Column({ space: 4 }) {
            Text('每日推荐歌曲')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))

            Text('根据你的听歌偏好更新')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Text('进入')
            .fontSize(14)
            .fontColor($r('app.color.text_brand'))
        }
        .width('100%')
        .padding(14)
        .backgroundColor($r('app.color.surface_card'))
        .borderRadius(8)
        .onClick(() => {
          hilog.info(DOMAIN, 'NavRoute', 'pushPath: DailyRecommendPage');
          this.pathStack.pushPath({ name: 'DailyRecommendPage' });
          AppStorage.setOrCreate<number>('mainNavDepth', this.pathStack.size());
        })

        ToplistRow();
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 16, right: 16, top: 16, bottom: TAB_PAGE_BOTTOM_PADDING_VP })
    }
    .width('100%')
    .height('100%')
    .scrollable(ScrollDirection.Vertical)
    .align(Alignment.TopStart)
  }
}
