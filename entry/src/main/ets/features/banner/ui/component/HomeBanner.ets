import { Banner } from '../../domain/model/BannerModels';
import { BannerApi } from '../../data/api/BannerApi';
import { BannerRepositoryImpl } from '../../data/repository/BannerRepositoryImpl';
import { GetBannersUseCase } from '../../domain/usecase/GetBannersUseCase';
import { promptAction, router } from '@kit.ArkUI';
import common from '@ohos.app.ability.common';
import { PlayerEngine } from '../../../music/service/PlayerEngine';

@Component
export struct HomeBanner {
  @State private banners: Banner[] = [];
  @State private isLoading: boolean = true;
  @State private errorMessage: string = '';

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

    if (targetUrl.startsWith('orpheus://')) {
      await this.handleInternalJump(targetUrl);
    } else if (targetUrl.startsWith('http://') || targetUrl.startsWith('https://')) {
      try {
        const context = getContext(this) as common.UIAbilityContext;
        await context.startAbility({
          action: 'ohos.want.action.viewData',
          uri: targetUrl
        });
      } catch (error) {
        console.error(`open external url failed: ${targetUrl}, ${(error as Error).message}`);
        promptAction.showToast({ message: '外链打开失败' });
      }
    } else {
      promptAction.showToast({ message: '暂不支持该类型跳转' });
    }
    console.info(`banner click: ${targetUrl}`);
  }

  private async handleInternalJump(url: string): Promise<void> {
    const songPrefix = 'orpheus://song/';
    if (!url.startsWith(songPrefix)) {
      promptAction.showToast({ message: '暂不支持该站内链接类型' });
      return;
    }

    const rawId = url.slice(songPrefix.length);
    const songId = Number.parseInt(rawId, 10);
    if (Number.isNaN(songId)) {
      promptAction.showToast({ message: '歌曲 ID 无效' });
      return;
    }

    try {
      await this.engine.playSong(songId);
    } catch (error) {
      promptAction.showToast({ message: '歌曲播放失败' });
    }

    router.pushUrl({
      url: 'pages/MusicPlayerPage',
      params: {
        songId: songId
      }
    });
  }

  build() {
    Column({ space: 8 }) {
      if (this.isLoading) {
        Text('Banner 加载中...')
          .fontSize(14)
          .fontColor('#666666')
      } else if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor('#d94841')

        Button('重试')
          .onClick(() => {
            this.loadBanners();
          })
      } else if (this.banners.length === 0) {
        Text('暂无 Banner 数据')
          .fontSize(14)
          .fontColor('#666666')
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
