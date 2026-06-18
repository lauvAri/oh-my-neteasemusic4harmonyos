import common from '@ohos.app.ability.common';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HomeBanner } from '../features/banner/ui/component/HomeBanner';
import { RecommendPlaylistRow } from '../features/music/playlist/ui/component/RecommendPlaylistRow';
import { ToplistRow } from '../features/music/playlist/ui/component/ToplistRow';
import { TAB_PAGE_BOTTOM_PADDING_VP } from '../common/ui/PageLayout';
import { AuthService } from '../features/auth/service/AuthService';

const DOMAIN = 0x0000;
const GUEST_LOGIN_TIMEOUT_MS: number = 5000;

@Component
export struct HomePage {
  @Consume('pathStack') pathStack: NavPathStack;
  @State private isReady: boolean = false;
  @State private placeholderText: string = '正在初始化游客会话...';

  private authService?: AuthService;

  aboutToAppear(): void {
    void this.bootstrapGuestSession();
  }

  private async bootstrapGuestSession(): Promise<void> {
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      this.authService = new AuthService(context);

      // 快速通道:已有真实用户 cookie(扫码登录过)就跳过游客登录
      const existingCookie: string = await this.authService.getCookie();
      if (existingCookie.length > 0 && !existingCookie.startsWith('NMTID=')) {
        this.isReady = true;
        return;
      }

      // 与网络请求并行设置 5s 超时,避免后端慢导致 Loading 卡死
      const timeout: Promise<void> = new Promise<void>((resolve) => {
        setTimeout(() => {
          this.placeholderText = '加载中...';
          resolve();
        }, GUEST_LOGIN_TIMEOUT_MS);
      });

      const login: Promise<void> = this.authService
        .loginAnonymously()
        .then(() => undefined)
        .catch(() => undefined);

      await Promise.race<void>([login, timeout]);
    } finally {
      this.isReady = true;
    }
  }

  build() {
    Stack() {
      if (this.isReady) {
        this.buildContent();
      } else {
        this.buildPlaceholder();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.surface_subtle'))
  }

  @Builder
  private buildContent() {
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

  @Builder
  private buildPlaceholder() {
    Column({ space: 12 }) {
      LoadingProgress()
        .width(36)
        .height(36)
        .color($r('app.color.text_brand'))

      Text(this.placeholderText)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
