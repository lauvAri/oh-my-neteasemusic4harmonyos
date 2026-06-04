import common from '@ohos.app.ability.common';
import { promptAction, router } from '@kit.ArkUI';
import { AuthService, UserAccountResponse } from '../features/auth/service/AuthService';

@Component
export struct MinePage {
  @State loading: boolean = false;
  @State loaded: boolean = false;
  @State errorText: string = '';
  @State nickname: string = '';
  @State avatarUrl: string = '';
  @State backgroundUrl: string = '';
  @State signature: string = '';
  @State userId: number = 0;
  @State userName: string = '';
  @State accountName: string = '';
  @State profileVipType: number = 0;
  @State accountVipType: number = 0;

  private authService?: AuthService;

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    this.authService = new AuthService(context);
    this.loadAccountInfo();
  }

  private async loadAccountInfo(): Promise<void> {
    if (this.authService === undefined || this.loading) {
      return;
    }

    this.loading = true;
    this.errorText = '';

    try {
      const cookie = await this.authService.getCookie();
      if (cookie.length === 0) {
        this.loaded = false;
        this.errorText = '未登录，请先完成二维码登录';
        return;
      }

      const response: UserAccountResponse = await this.authService.getAccountInfo();
      this.nickname = response.profile.nickname;
      this.avatarUrl = response.profile.avatarUrl;
      this.backgroundUrl = response.profile.backgroundUrl;
      this.signature = response.profile.signature === undefined ? '' : response.profile.signature;
      this.userId = response.profile.userId;
      this.userName = response.profile.userName;
      this.accountName = response.account.userName;
      this.profileVipType = response.profile.vipType;
      this.accountVipType = response.account.vipType;
      this.loaded = true;
    } catch (error) {
      this.loaded = false;
      this.errorText = `账号信息获取失败：${(error as Error).message}`;
      promptAction.showToast({ message: '账号信息获取失败' });
    } finally {
      this.loading = false;
    }
  }

  private async logout(): Promise<void> {
    await this.authService?.clearCookie();
    promptAction.showToast({ message: '已退出登录' });
    router.replaceUrl({ url: 'pages/Index' });
  }

  @Builder
  private infoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#777777')
        .width(88)
      Text(value)
        .fontSize(15)
        .fontColor('#222222')
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('我的')
          .fontSize(26)
          .fontWeight(FontWeight.Medium)
          .width('100%')

        if (this.loading && !this.loaded) {
          Column({ space: 12 }) {
            LoadingProgress()
              .width(44)
              .height(44)
            Text('正在获取账号信息...')
              .fontSize(14)
              .fontColor('#666666')
          }
          .width('100%')
          .height(220)
          .justifyContent(FlexAlign.Center)
        } else if (this.loaded) {
          Column({ space: 16 }) {
            Stack({ alignContent: Alignment.BottomStart }) {
              if (this.backgroundUrl.length > 0) {
                Image(this.backgroundUrl)
                  .width('100%')
                  .height(150)
                  .objectFit(ImageFit.Cover)
              } else {
                Blank()
                  .width('100%')
                  .height(150)
                  .backgroundColor('#f1f3f5')
              }

              Row({ space: 12 }) {
                Image(this.avatarUrl)
                  .width(72)
                  .height(72)
                  .objectFit(ImageFit.Cover)
                  .border({ width: 2, color: '#ffffff', radius: 36 })

                Column({ space: 4 }) {
                  Text(this.nickname)
                    .fontSize(22)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#ffffff')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(this.signature.length > 0 ? this.signature : '这个人很懒，什么都没写')
                    .fontSize(13)
                    .fontColor('#f5f5f5')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .layoutWeight(1)
              }
              .width('100%')
              .padding(14)
              .linearGradient({
                angle: 0,
                colors: [['rgba(0,0,0,0.62)', 0], ['rgba(0,0,0,0)', 1]]
              })
            }
            .width('100%')
            .height(150)
            .borderRadius(8)
            .clip(true)

            Column({ space: 12 }) {
              this.infoRow('用户 ID', `${this.userId}`);
              this.infoRow('用户名', this.userName.length > 0 ? this.userName : this.accountName);
              this.infoRow('账号 VIP', `${this.accountVipType}`);
              this.infoRow('资料 VIP', `${this.profileVipType}`);
            }
            .width('100%')
            .padding(14)
            .backgroundColor('#f8f9fa')
            .borderRadius(8)

            Row({ space: 10 }) {
              Button('刷新信息')
                .layoutWeight(1)
                .onClick(() => {
                  this.loadAccountInfo();
                })
              Button('退出登录')
                .layoutWeight(1)
                .fontColor('#d4380d')
                .backgroundColor('#fff1e8')
                .onClick(() => {
                  this.logout();
                })
            }
            .width('100%')
          }
          .width('100%')
        } else {
          Column({ space: 12 }) {
            Text(this.errorText)
              .fontSize(14)
              .fontColor('#666666')
              .textAlign(TextAlign.Center)
            Button('返回登录')
              .onClick(() => {
                router.replaceUrl({ url: 'pages/Index' });
              })
          }
          .width('100%')
          .height(220)
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .height('100%')
  }
}
