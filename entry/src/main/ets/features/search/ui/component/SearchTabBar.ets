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
          .fontColor(this.activeTab === option.type ? Color.White : '#1f2937')
          .backgroundColor(this.activeTab === option.type ? '#1677ff' : '#f2f3f5')
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
