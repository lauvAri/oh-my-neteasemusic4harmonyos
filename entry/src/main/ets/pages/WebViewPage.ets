import { webview } from '@kit.ArkWeb';
import { promptAction } from '@kit.ArkUI';
import { GlassSurface } from '../common/ui/GlassSurface';
import { getSubpageBottomPaddingVp } from '../common/ui/PageLayout';
import { OrpheusUrlRouter, OrpheusRoute } from '../common/util/OrpheusUrlRouter';
import { PlayerEngine } from '../features/music/service/PlayerEngine';

interface WebViewParams {
  url: string;
  title?: string;
}

@Component
export struct WebViewPage {
  @Prop url: string = '';
  @Prop title: string = '';
  @StorageLink('miniPlayerVisible') miniPlayerVisible: boolean = false;
  @Consume('pathStack') pathStack: NavPathStack;
  private controller: webview.WebviewController = new webview.WebviewController();
  @State resolvedTitle: string = '';
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    if (this.url.length === 0) {
      this.hasError = true;
      this.errorMessage = '链接地址无效';
      this.isLoading = false;
      return;
    }
    this.resolvedTitle = this.title.length > 0 ? this.title : this.extractHost(this.url);
  }

  private extractHost(rawUrl: string): string {
    try {
      const match = rawUrl.match(/^https?:\/\/([^/?#]+)/i);
      if (match !== null && match.length > 1) {
        return match[1];
      }
    } catch (error) {
      console.error(`extract host failed: ${(error as Error).message}`);
    }
    return '网页';
  }

  private handleInterceptedUrl(rawUrl: string): boolean {
    const route: OrpheusRoute = OrpheusUrlRouter.parse(rawUrl);
    if (route.handled) {
      if (route.action === 'web') {
        return false;
      }
      if (route.action === 'download') {
        this.controller.stop();
        promptAction.showToast({ message: '已拦截网易云音乐下载跳转' });
        console.info(`webview blocked download url=${rawUrl}`);
        return true;
      }
      this.applyParsedRoute(route);
      this.controller.stop();
      return true;
    }
    const lower: string = (rawUrl ?? '').toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return false;
    }
    this.controller.stop();
    promptAction.showToast({ message: '暂不支持该类型链接' });
    console.info(`webview blocked unsupported url=${rawUrl}`);
    return true;
  }

  private async applyParsedRoute(route: OrpheusRoute): Promise<void> {
    switch (route.action) {
      case 'song':
        await this.playSong(route.targetId);
        return;
      case 'album':
        this.pushDetail('AlbumDetailPage', route.targetId);
        return;
      case 'artist':
        this.pushDetail('ArtistDetailPage', route.targetId);
        return;
      case 'playlist':
        this.pushDetail('PlaylistDetailPage', route.targetId);
        return;
      default:
        return;
    }
  }

  private async playSong(songId: number): Promise<void> {
    try {
      await PlayerEngine.getInstance().playSong(songId);
    } catch (error) {
      promptAction.showToast({ message: '歌曲播放失败' });
      console.error(`webview play song failed: ${(error as Error).message}`);
    }
  }

  private pushDetail(name: string, id: number): void {
    this.pathStack.pushPath({ name: name, param: id });
    AppStorage.setOrCreate<number>('mainNavDepth', this.pathStack.size());
  }

  private handleBack(): void {
    if (this.pathStack.size() > 0) {
      this.pathStack.pop();
      AppStorage.setOrCreate<number>('mainNavDepth', this.pathStack.size());
    }
  }

  build() {
    Column() {
      GlassSurface({
        blurStyle: BlurStyle.Regular,
        radius: 18,
        contentSpacing: 0,
        contentPadding: { left: 12, right: 12, top: 8, bottom: 8 },
        content: (): void => {
          this.header();
        }
      })
        .width('100%')

      if (this.hasError) {
        Column({ space: 12 }) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor($r('app.color.text_danger'))
          Button('返回')
            .onClick(() => {
              this.handleBack();
            })
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Stack({ alignContent: Alignment.Top }) {
          Web({ src: this.url, controller: this.controller })
            .width('100%')
            .height('100%')
            .javaScriptAccess(true)
            .domStorageAccess(true)
            .fileAccess(true)
            .onlineImageAccess(true)
            .imageAccess(true)
            .mixedMode(MixedMode.All)
            .onLoadIntercept((event) => {
              const data = event?.data;
              const raw: string = data?.getRequestUrl() ?? '';
              return this.handleInterceptedUrl(raw);
            })
            .onPageBegin((event) => {
              this.isLoading = true;
              this.hasError = false;
              const navigatedUrl: string = event?.url ?? '';
              const route: OrpheusRoute = OrpheusUrlRouter.parse(navigatedUrl);
              if (route.handled && route.action === 'download') {
                this.controller.stop();
                if (this.url.length > 0) {
                  this.controller.loadUrl(this.url);
                }
                promptAction.showToast({ message: '已拦截网易云音乐下载跳转' });
                console.info(`webview onPageBegin blocked download url=${navigatedUrl}`);
              }
            })
            .onPageEnd(() => {
              this.isLoading = false;
            })
            .onErrorReceive((event) => {
              if (event !== undefined && event !== null && event.error !== undefined && event.error !== null) {
                this.hasError = true;
                this.errorMessage = event.error.getErrorInfo();
              }
              this.isLoading = false;
            })

          if (this.isLoading) {
            Column({ space: 8 }) {
              LoadingProgress()
                .width(36)
                .height(36)
                .color($r('app.color.text_brand'))
              Text('加载中...')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#22000000')
          }
        }
        .layoutWeight(1)
        .width('100%')
      }

      Blank().height(getSubpageBottomPaddingVp(this.miniPlayerVisible))
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .padding({ left: 12, right: 12, top: 12 })
  }

  @Builder
  private header() {
    Row({ space: 12 }) {
      Button() {
        Image($r('app.media.ic_arrow_back'))
          .width(18)
          .height(18)
          .fillColor($r('app.color.icon_primary'))
      }
      .type(ButtonType.Circle)
      .width(36)
      .height(36)
      .backgroundColor($r('app.color.surface_subtle'))
      .onClick(() => {
        this.handleBack();
      })

      Text(this.resolvedTitle)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%')
  }
}

export { WebViewParams };
