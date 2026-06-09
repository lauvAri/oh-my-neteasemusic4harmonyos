import { HomePage } from './HomePage';
import { MinePage } from './MinePage';
import { SearchPage } from './SearchPage';
import { DailyRecommendPage } from './DailyRecommendPage';
import { PlaylistDetailPage } from './PlaylistDetailPage';
import { ArtistDetailPage } from './ArtistDetailPage';
import { AlbumDetailPage } from './AlbumDetailPage';
import { MiniPlayerBar } from '../features/music/ui/mini/MiniPlayerBar';
import { PlayerEngine } from '../features/music/service/PlayerEngine';
import common from '@ohos.app.ability.common';
import { HttpClient } from '../common/network/HttpClient';
import { SessionStore } from '../common/storage/SessionStore';
import { GlassSurface } from '../common/ui/GlassSurface';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;

@Builder
function MainTabsRouteMap(name: string, param: Object) {
  if (name === 'SearchPage') {
    NavDestination() {
      SearchPage();
    }
    .hideTitleBar(true)
  } else if (name === 'DailyRecommendPage') {
    NavDestination() {
      DailyRecommendPage();
    }
    .hideTitleBar(true)
  } else if (name === 'PlaylistDetailPage') {
    NavDestination() {
      PlaylistDetailPage({ playlistId: param as number });
    }
    .hideTitleBar(true)
  } else if (name === 'ArtistDetailPage') {
    NavDestination() {
      ArtistDetailPage({ artistId: param as number });
    }
    .hideTitleBar(true)
  } else if (name === 'AlbumDetailPage') {
    NavDestination() {
      AlbumDetailPage({ albumId: param as number });
    }
    .hideTitleBar(true)
  }
}

@Entry
@Component
struct MainTabs {
  @Provide('pathStack') pathStack: NavPathStack = new NavPathStack();
  @State currentIndex: number = 0;
  @StorageLink('mainNavDepth') pathDepth: number = 0;
  @StorageLink('miniPlayerVisible') miniPlayerVisible: boolean = false;
  private tabsController: TabsController = new TabsController();

  private engine: PlayerEngine = PlayerEngine.getInstance();

  aboutToAppear(): void {
    AppStorage.setOrCreate<number>('mainNavDepth', this.pathStack.size());
    const context = getContext(this) as common.UIAbilityContext;
    HttpClient.setGlobalCookieProvider(new SessionStore(context));
    this.engine.initSession(context).catch((error: Error) => {
      console.error(`init session failed: ${error.message}`);
    });
  }

  onPageShow(): void {
    const target = AppStorage.get<string>('pendingNavTarget');
    if (target !== undefined && target !== null && target.length > 0) {
      AppStorage.setOrCreate<string>('pendingNavTarget', '');
      try {
        const parsed = JSON.parse(target) as Record<string, Object>;
        const page = parsed['page'] as string;
        const id = parsed['id'] as number;
        this.pathStack.pushPath({ name: page, param: id });
      } catch (error) {
        hilog.error(DOMAIN, 'NavRoute', `pending nav failed: ${(error as Error).message}`);
      }
    }
  }

  @Builder
  private tabButton(title: string, index: number) {
    Button(title)
      .type(ButtonType.Normal)
      .fontSize(14)
      .fontColor(this.currentIndex === index ? $r('app.color.text_brand') : $r('app.color.text_brand_inactive'))
      .backgroundColor(this.currentIndex === index ? $r('app.color.surface_brand_tint') : Color.Transparent)
      .height(36)
      .layoutWeight(1)
      .borderRadius(18)
      .onClick(() => {
        this.tabsController.changeIndex(index);
        this.currentIndex = index;
      })
  }

  @Builder
  private fullDockContent() {
    Column({ space: this.miniPlayerVisible ? 8 : 0 }) {
      if (this.miniPlayerVisible) {
        MiniPlayerBar();
      }

      Row({ space: 8 }) {
        this.tabButton('首页', 0);
        this.tabButton('我的', 1);
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private miniDockContent() {
    MiniPlayerBar();
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Navigation(this.pathStack) {
        NavDestination() {
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
        }
        .hideTitleBar(true)
        .mode(NavDestinationMode.STANDARD)
      }
      .width('100%')
      .height('100%')
      .navDestination(MainTabsRouteMap)
      .hideTitleBar(true)
      .mode(NavigationMode.Stack)
      .onAppear(() => {
        AppStorage.setOrCreate<number>('mainNavDepth', this.pathStack.size());
        hilog.info(DOMAIN, 'NavRoute', 'Navigation appeared, pathStack size=' + this.pathStack.size());
      })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])

      if (this.pathDepth === 0) {
        GlassSurface({
          blurStyle: BlurStyle.Thin,
          radius: 24,
          contentSpacing: this.miniPlayerVisible ? 8 : 0,
          contentPadding: { left: 12, right: 12, top: 10, bottom: 10 },
          content: () => { this.fullDockContent(); }
        })
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 12 })
          .zIndex(10)
      } else if (this.miniPlayerVisible) {
        GlassSurface({
          blurStyle: BlurStyle.Thin,
          radius: 18,
          contentSpacing: 0,
          contentPadding: { left: 12, right: 12, top: 8, bottom: 8 },
          content: () => { this.miniDockContent(); }
        })
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 12 })
          .zIndex(10)
      }
    }
    .width('100%')
    .height('100%')
  }
}
