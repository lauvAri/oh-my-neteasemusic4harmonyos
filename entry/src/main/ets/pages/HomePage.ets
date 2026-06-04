import { HomeBanner } from '../features/banner/ui/component/HomeBanner';

@Component
export struct HomePage {
  build() {
    Column({ space: 16 }) {
      Text('首页')
        .fontSize(26)
        .fontWeight(FontWeight.Medium)

      HomeBanner();
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
  }
}
