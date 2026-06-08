import { SearchType, SearchTypeOption, SEARCH_TYPE_OPTIONS } from '../../domain/model/SearchModels';

@Component
export struct SearchTabBar {
  @Prop activeTab: SearchType = 'song';
  onTabChange: (type: SearchType) => void = () => {};

  build() {
    Row({ space: 8 }) {
      ForEach(SEARCH_TYPE_OPTIONS, (option: SearchTypeOption) => {
        Text(option.label)
          .fontSize(14)
          .fontColor(this.activeTab === option.type ? $r('app.color.text_on_dark_primary') : $r('app.color.text_primary'))
          .backgroundColor(this.activeTab === option.type ? $r('app.color.text_brand') : $r('app.color.surface_input'))
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .borderRadius(16)
          .onClick(() => {
            this.onTabChange(option.type);
          })
      }, (option: SearchTypeOption) => option.type)
    }
    .width('100%')
  }
}
