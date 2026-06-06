import { router } from '@kit.ArkUI';
import { MusicPlayerCard } from '../features/music/ui/component/MusicPlayerCard';

const BACK_BUTTON_SIZE_VP: number = 48;
const BACK_BUTTON_ICON_VP: number = 24;
const TOP_BAR_INNER_PADDING_VP: number = 10;
const TOP_BAR_GAP_VP: number = 8;
const BG_TOP_COLOR: string = '#1f2937';
const BG_BOTTOM_COLOR: string = '#0b1220';

@Entry
@Component
struct MusicPlayerPage {
  @State private songId: number = 1969519579;

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>;
    const rawSongId = params['songId'];
    if (typeof rawSongId === 'number') {
      this.songId = rawSongId;
    } else if (typeof rawSongId === 'string') {
      const parsed = Number.parseInt(rawSongId, 10);
      if (!Number.isNaN(parsed)) {
        this.songId = parsed;
      }
    }
    AppStorage.setOrCreate<string>('currentDetailCover', '');
  }

  aboutToDisappear(): void {
    AppStorage.setOrCreate<string>('currentDetailCover', '');
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [
            [BG_TOP_COLOR, 0.0],
            [BG_BOTTOM_COLOR, 1.0]
          ]
        })
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      Column() {
        this.TopBar()
        MusicPlayerCard({ songId: this.songId })
          .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private TopBar() {
    Row() {
      Button() {
        Image($r('app.media.ic_arrow_back'))
          .width(BACK_BUTTON_ICON_VP)
          .height(BACK_BUTTON_ICON_VP)
          .fillColor('#ffffff')
      }
        .type(ButtonType.Circle)
        .width(BACK_BUTTON_SIZE_VP)
        .height(BACK_BUTTON_SIZE_VP)
        .backgroundColor('#40ffffff')
        .onClick(() => {
          router.back();
        })

      Blank()

      Text('正在播放')
        .fontSize(13)
        .fontColor('rgba(255, 255, 255, 0.85)')
        .fontWeight(FontWeight.Medium)
        .margin({ right: 8 })

      Blank()
    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: TOP_BAR_INNER_PADDING_VP,
      bottom: TOP_BAR_INNER_PADDING_VP
    })
    .margin({ bottom: TOP_BAR_GAP_VP })
  }
}
