import { HomePage } from './HomePage';
import { MinePage } from './MinePage';
import { MiniPlayerBar } from '../features/music/ui/mini/MiniPlayerBar';
import { PlayerEngine } from '../features/music/service/PlayerEngine';
import common from '@ohos.app.ability.common';
import { HttpClient } from '../common/network/HttpClient';
import { SessionStore } from '../common/storage/SessionStore';

@Entry
@Component
struct MainTabs {
  @State currentIndex: number = 0;
  private tabsController: TabsController = new TabsController();

  private engine: PlayerEngine = PlayerEngine.getInstance();

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    HttpClient.setGlobalCookieProvider(new SessionStore(context));
    this.engine.initSession(context).catch((error: Error) => {
      console.error(`init session failed: ${error.message}`);
    });
  }

  @Builder
  private tabButton(title: string, index: number) {
    Button(title)
      .type(ButtonType.Normal)
      .fontSize(14)
      .fontColor(this.currentIndex === index ? '#1677ff' : '#666666')
      .backgroundColor(this.currentIndex === index ? '#e8f1ff' : '#f3f4f6')
      .height(36)
      .layoutWeight(1)
      .onClick(() => {
        this.tabsController.changeIndex(index);
        this.currentIndex = index;
      })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Tabs({
        barPosition: BarPosition.End,
        index: this.currentIndex,
        controller: this.tabsController
      }) {
        TabContent() {
          HomePage()
            .width('100%')
            .height('100%')
        }
        .tabBar('首页')

        TabContent() {
          Column() {
            MinePage();
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Start)
        }
        .tabBar('我的')
      }
      .vertical(false)
      .barMode(BarMode.Fixed)
      .barHeight(0)
      .width('100%')
      .height('100%')
      .onChange((index: number) => {
        this.currentIndex = index;
      })

      Column({ space: 8 }) {
        MiniPlayerBar();

        Row({ space: 8 }) {
          this.tabButton('首页', 0);
          this.tabButton('我的', 1);
        }
        .width('100%')
      }
      .width('100%')
      .backgroundColor('#ffffff')
    }
    .width('100%')
    .height('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 6 })
  }
}
