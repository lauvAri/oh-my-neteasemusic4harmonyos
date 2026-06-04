import common from '@ohos.app.ability.common';
import { promptAction, router } from '@kit.ArkUI';
import { AuthService, QrLoginSession } from '../features/auth/service/AuthService';

@Entry
@Component
struct Index {
  @State qrImage: string = '';
  @State statusText: string = '正在生成登录二维码...';
  @State loading: boolean = false;
  @State qrKey: string = '';

  private authService?: AuthService;
  private pollTimerId: number = -1;

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    this.authService = new AuthService(context);
    this.tryEnterWithSavedCookie();
  }

  aboutToDisappear(): void {
    this.stopPolling();
  }

  private async tryEnterWithSavedCookie(): Promise<void> {
    const cookie = await this.authService?.getCookie();
    if (cookie !== undefined && cookie.length > 0) {
      router.replaceUrl({ url: 'pages/MainTabs' });
      return;
    }
    this.refreshQrCode();
  }

  private async refreshQrCode(): Promise<void> {
    if (this.authService === undefined || this.loading) {
      return;
    }

    this.loading = true;
    this.statusText = '正在生成登录二维码...';
    this.stopPolling();

    try {
      const session: QrLoginSession = await this.authService.createQrLogin();
      this.qrKey = session.key;
      this.qrImage = session.qrimg;
      this.statusText = '请使用网易云音乐 App 扫码登录';
      this.startPolling();
    } catch (error) {
      this.statusText = `二维码生成失败：${(error as Error).message}`;
      promptAction.showToast({ message: '二维码生成失败' });
    } finally {
      this.loading = false;
    }
  }

  private startPolling(): void {
    this.stopPolling();
    this.pollTimerId = setInterval(() => {
      this.checkQrStatus();
    }, 2000);
  }

  private stopPolling(): void {
    if (this.pollTimerId !== -1) {
      clearInterval(this.pollTimerId);
      this.pollTimerId = -1;
    }
  }

  private async checkQrStatus(): Promise<void> {
    if (this.authService === undefined || this.qrKey.length === 0) {
      return;
    }

    try {
      const response = await this.authService.checkQrLogin(this.qrKey);
      if (response.code === 801) {
        this.statusText = '请使用网易云音乐 App 扫码登录';
      } else if (response.code === 802) {
        this.statusText = '已扫码，请在手机上确认登录';
      } else if (response.code === 803) {
        this.statusText = '登录成功';
        this.stopPolling();
        promptAction.showToast({ message: '登录成功' });
        router.replaceUrl({ url: 'pages/MainTabs' });
      } else if (response.code === 800) {
        this.statusText = '二维码已过期，请刷新';
        this.stopPolling();
      }
    } catch (error) {
      this.statusText = `登录状态检查失败：${(error as Error).message}`;
    }
  }

  build() {
    Column({ space: 18 }) {
      Text('网易云音乐二维码登录')
        .fontSize(24)
        .fontWeight(FontWeight.Medium)

      if (this.qrImage.length > 0) {
        Image(this.qrImage)
          .width(220)
          .height(220)
          .objectFit(ImageFit.Contain)
          .border({ width: 1, color: '#e5e7eb', radius: 8 })
          .padding(10)
      } else {
        Column() {
          LoadingProgress()
            .width(44)
            .height(44)
        }
        .width(220)
        .height(220)
        .justifyContent(FlexAlign.Center)
        .border({ width: 1, color: '#e5e7eb', radius: 8 })
      }

      Text(this.statusText)
        .fontSize(15)
        .fontColor('#555555')
        .textAlign(TextAlign.Center)
        .width('100%')

      Button(this.loading ? '生成中...' : '刷新二维码')
        .enabled(!this.loading)
        .height(42)
        .width(160)
        .onClick(() => {
          this.refreshQrCode();
        })
    }
    .width('100%')
    .height('100%')
    .padding(24)
    .justifyContent(FlexAlign.Center)
  }
}
