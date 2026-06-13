import { router } from '@kit.ArkUI';
import { MusicPlayerCard } from '../features/music/ui/component/MusicPlayerCard';
import { PlayerBackgroundPalette, PlayerBackgroundResolver } from '../features/music/ui/background/PlayerBackgroundResolver';

const BACK_BUTTON_SIZE_VP: number = 48;
const BACK_BUTTON_ICON_VP: number = 24;
const TOP_BAR_INNER_PADDING_VP: number = 10;
const TOP_BAR_GAP_VP: number = 8;
const BG_ANIMATION_DURATION_MS: number = 480;

@Entry
@Component
struct MusicPlayerPage {
  @State private songId: number = 1969519579;
  @StorageLink('miniPlayerTitle') private miniPlayerTitle: string = '未选择歌曲';
  @StorageLink('currentDetailCover') @Watch('onCoverChanged') private currentDetailCover: string = '';
  @State private activePalette: PlayerBackgroundPalette = PlayerBackgroundResolver.defaultPalette();
  @State private incomingPalette: PlayerBackgroundPalette = PlayerBackgroundResolver.defaultPalette();
  @State private backgroundBlend: number = 1;
  private paletteCommitTimer: number = -1;

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
    this.applyCoverPalette('');
  }

  aboutToDisappear(): void {
    if (this.paletteCommitTimer >= 0) {
      clearTimeout(this.paletteCommitTimer);
      this.paletteCommitTimer = -1;
    }
    AppStorage.setOrCreate<string>('currentDetailCover', '');
  }

  private onCoverChanged(): void {
    this.applyCoverPalette(this.currentDetailCover);
  }

  private applyCoverPalette(coverUrl: string): void {
    if (this.paletteCommitTimer >= 0) {
      clearTimeout(this.paletteCommitTimer);
      this.paletteCommitTimer = -1;
    }
    const nextPalette = PlayerBackgroundResolver.resolveFromCover(coverUrl);
    this.incomingPalette = nextPalette;
    this.backgroundBlend = 0;
    animateTo({
      duration: BG_ANIMATION_DURATION_MS,
      curve: Curve.EaseInOut
    }, () => {
      this.backgroundBlend = 1;
    });
    this.paletteCommitTimer = setTimeout(() => {
      this.commitPaletteAfterAnimation();
      this.paletteCommitTimer = -1;
    }, BG_ANIMATION_DURATION_MS + 40);
  }

  private commitPaletteAfterAnimation(): void {
    this.activePalette = this.incomingPalette;
    this.backgroundBlend = 1;
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // Base palette layer.
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [
            [this.activePalette.topColor, 0.0],
            [this.activePalette.middleColor, 0.46],
            [this.activePalette.bottomColor, 1.0]
          ]
        })
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      // Incoming palette layer, cross-faded for smooth transitions.
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [
            [this.incomingPalette.topColor, 0.0],
            [this.incomingPalette.middleColor, 0.46],
            [this.incomingPalette.bottomColor, 1.0]
          ]
        })
        .opacity(this.backgroundBlend)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      // Soft center glow to avoid a flat wall-like background.
      Column()
        .width('100%')
        .height('100%')
        .radialGradient({
          center: ['50%', '35%'],
          radius: '68%',
          colors: [
            [this.incomingPalette.glowColor, 0.0],
            ['rgba(18, 24, 38, 0.35)', 0.42],
            ['rgba(10, 14, 24, 0.0)', 1.0]
          ]
        })
        .opacity(0.38 + this.backgroundBlend * 0.12)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      // Readability guard layers: keep lyrics readable over all covers.
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [
            ['rgba(2, 4, 10, 0.38)', 0.0],
            ['rgba(2, 4, 10, 0.20)', 0.28],
            ['rgba(2, 4, 10, 0.54)', 1.0]
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
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.back();
        })

      Text(this.miniPlayerTitle)
        .fontSize(14)
        .fontColor('rgba(255, 255, 255, 0.85)')
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .margin({ left: 12, right: 12 })
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
