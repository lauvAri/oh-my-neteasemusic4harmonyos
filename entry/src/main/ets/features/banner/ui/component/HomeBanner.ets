import { Banner } from '../../domain/model/BannerModels';
import { BannerApi } from '../../data/api/BannerApi';
import { BannerRepositoryImpl } from '../../data/repository/BannerRepositoryImpl';
import { GetBannersUseCase } from '../../domain/usecase/GetBannersUseCase';
import { promptAction } from '@kit.ArkUI';
import { PlayerEngine } from '../../../music/service/PlayerEngine';
import { OrpheusUrlRouter, OrpheusRoute } from '../../../../common/util/OrpheusUrlRouter';

const TARGET_TYPE_SONG: number = 1;
const TARGET_TYPE_ALBUM: number = 10;
const TARGET_TYPE_ARTIST: number = 100;
const TARGET_TYPE_PLAYLIST: number = 1000;

interface WebViewRoute {
  url: string;
  title: string;
}

@Component
export struct HomeBanner {
  @State private banners: Banner[] = [];
  @State private isLoading: boolean = true;
  @State private errorMessage: string = '';
  @Consume('pathStack') pathStack: NavPathStack;

  private getBannersUseCase: GetBannersUseCase =
    new GetBannersUseCase(new BannerRepositoryImpl(new BannerApi()));
  private engine: PlayerEngine = PlayerEngine.getInstance();

  aboutToAppear(): void {
    this.loadBanners();
  }

  private async loadBanners(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      this.banners = await this.getBannersUseCase.execute();
    } catch (error) {
      const message = (error as Error).message;
      this.errorMessage = message.length > 0 ? message : 'Banner 加载失败';
    } finally {
      this.isLoading = false;
    }
  }

  private async handleBannerClick(banner: Banner): Promise<void> {
    const targetUrl = banner.url;
    if (!targetUrl || targetUrl.length === 0) {
      promptAction.showToast({ message: '该 Banner 无可用跳转地址' });
      return;
    }

    const handled = await this.routeByTargetType(banner);
    if (handled) {
      console.info(`banner click: type=${banner.targetType}, id=${banner.targetId}, url=${targetUrl}`);
      return;
    }

    const route = OrpheusUrlRouter.parse(targetUrl);
    if (!route.handled) {
      promptAction.showToast({ message: '暂不支持该类型跳转' });
      console.info(`banner click: unsupported url=${targetUrl}`);
      return;
    }

    if (route.action === 'web' && route.httpUrl) {
      this.openWebView(route.httpUrl, banner.typeTitle);
      console.info(`banner click: web url=${route.httpUrl}`);
      return;
    }

    await this.applyParsedRoute(route, targetUrl);
  }

  private async applyParsedRoute(route: OrpheusRoute, rawUrl: string): Promise<void> {
    switch (route.action) {
      case 'song':
        await this.playSong(route.targetId);
        console.info(`banner click: scheme url=${rawUrl}`);
        return;
      case 'album':
        this.pushDetail('AlbumDetailPage', route.targetId);
        console.info(`banner click: scheme url=${rawUrl}`);
        return;
      case 'artist':
        this.pushDetail('ArtistDetailPage', route.targetId);
        console.info(`banner click: scheme url=${rawUrl}`);
        return;
      case 'playlist':
        this.pushDetail('PlaylistDetailPage', route.targetId);
        console.info(`banner click: scheme url=${rawUrl}`);
        return;
      default:
        return;
    }
  }

  private async routeByTargetType(banner: Banner): Promise<boolean> {
    switch (banner.targetType) {
      case TARGET_TYPE_SONG:
        await this.playSong(banner.targetId);
        return true;
      case TARGET_TYPE_ALBUM:
        this.pushDetail('AlbumDetailPage', banner.targetId);
        return true;
      case TARGET_TYPE_ARTIST:
        this.pushDetail('ArtistDetailPage', banner.targetId);
        return true;
      case TARGET_TYPE_PLAYLIST:
        this.pushDetail('PlaylistDetailPage', banner.targetId);
        return true;
      default:
        return false;
    }
  }

  private pushDetail(name: string, id: number): void {
    this.pathStack.pushPath({ name: name, param: id });
    AppStorage.setOrCreate<number>('mainNavDepth', this.pathStack.size());
  }

  private openWebView(url: string, typeTitle: string): void {
    const route: WebViewRoute = {
      url: url,
      title: typeTitle
    };
    this.pathStack.pushPath({ name: 'WebViewPage', param: route });
    AppStorage.setOrCreate<number>('mainNavDepth', this.pathStack.size());
  }

  private async playSong(songId: number): Promise<void> {
    try {
      await this.engine.playSong(songId);
    } catch (error) {
      promptAction.showToast({ message: '歌曲播放失败' });
      console.error(`banner play song failed: ${(error as Error).message}`);
    }
  }

  build() {
    Column({ space: 8 }) {
      if (this.isLoading) {
        Text('Banner 加载中...')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
      } else if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor($r('app.color.text_danger'))

        Button('重试')
          .onClick(() => {
            this.loadBanners();
          })
      } else if (this.banners.length === 0) {
        Text('暂无 Banner 数据')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
      } else {
        Swiper() {
          ForEach(this.banners, (item: Banner) => {
            Stack({ alignContent: Alignment.BottomStart }) {
              Image(item.imageUrl)
                .width('100%')
                .height(160)
                .borderRadius(12)
                .objectFit(ImageFit.Cover)

              Text(item.typeTitle)
                .fontSize(12)
                .fontColor(Color.White)
                .backgroundColor('#99000000')
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .margin(8)
                .borderRadius(8)
            }
            .width('100%')
            .height(160)
            .onClick(async () => {
              await this.handleBannerClick(item);
            })
          }, (item: Banner) => `${item.targetId}-${item.imageUrl}`)
        }
        .height(160)
        .indicator(true)
        .autoPlay(true)
        .interval(3000)
        .curve(Curve.EaseInOut)
      }
    }
    .width('100%')
  }
}
