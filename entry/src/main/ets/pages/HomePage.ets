import { HomeBanner } from '../features/banner/ui/component/HomeBanner';
import { RecommendPlaylistRow } from '../features/music/playlist/ui/component/RecommendPlaylistRow';
import { ToplistRow } from '../features/music/playlist/ui/component/ToplistRow';
import { router } from '@kit.ArkUI';

@Component
export struct HomePage {
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
          }
          .type(ButtonType.Circle)
          .width(36)
          .height(36)
          .backgroundColor('#eceff3')
          .onClick(() => {
            router.pushUrl({ url: 'pages/SearchPage' });
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
              .fontColor('#1f2937')

            Text('根据你的听歌偏好更新')
              .fontSize(13)
              .fontColor('#666666')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Text('进入')
            .fontSize(14)
            .fontColor('#1677ff')
        }
        .width('100%')
        .padding(14)
        .backgroundColor('#f7f8fa')
        .borderRadius(8)
        .onClick(() => {
          router.pushUrl({ url: 'pages/DailyRecommendPage' });
        })

        ToplistRow();
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 16, right: 16, top: 16, bottom: 120 })
    }
    .width('100%')
    .height('100%')
    .scrollable(ScrollDirection.Vertical)
    .align(Alignment.TopStart)
  }
}
