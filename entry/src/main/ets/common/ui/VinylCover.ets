const VINYL_ROTATION_INTERVAL_MS: number = 33;     // ~30fps
const VINYL_DEGREES_PER_SECOND: number = 360 / 18; // 18s 一圈，黑胶般沉稳
const VINYL_DEGREES_PER_TICK: number =
  VINYL_DEGREES_PER_SECOND * (VINYL_ROTATION_INTERVAL_MS / 1000);

const VINYL_DISC_COLOR: string = '#0b0b0b';
const VINYL_GROOVE_COLOR: string = 'rgba(255, 255, 255, 0.05)';
const VINYL_HOLE_COLOR: string = '#000000';
const VINYL_CENTER_HOLE_VP: number = 14;

// 唱片刻槽：外圈一圈圈同心细环（仅在封面之外的边缘环带可见）
const GROOVE_PERCENTS: number[] = [98, 95, 92, 89, 86, 83, 80, 77, 74];

/**
 * 圆形旋转黑胶封面：播放时封面持续旋转，暂停时在当前角度定格。
 * 黑色带纹路唱片刻槽与中心 spindle 小孔保持静止，仅封面标签旋转。
 */
@Component
export struct VinylCover {
  @Prop coverUrl: string = '';
  @Prop discPercent: string = '86%'; // 整个黑胶的外径，保持与原封面一致
  @StorageLink('miniPlayerPlaying') @Watch('onPlayingChange') private playing: boolean = false;
  @State private coverAngle: number = 0;
  private rotationTimerId: number = -1;

  aboutToAppear(): void {
    if (this.playing) {
      this.startRotation();
    }
  }

  aboutToDisappear(): void {
    this.stopRotation();
  }

  private onPlayingChange(): void {
    if (this.playing) {
      this.startRotation();
    } else {
      this.stopRotation();
    }
  }

  private startRotation(): void {
    this.stopRotation();
    this.rotationTimerId = setInterval(() => {
      this.coverAngle = (this.coverAngle + VINYL_DEGREES_PER_TICK) % 360;
    }, VINYL_ROTATION_INTERVAL_MS);
  }

  private stopRotation(): void {
    if (this.rotationTimerId !== -1) {
      clearInterval(this.rotationTimerId);
      this.rotationTimerId = -1;
    }
  }

  @Builder
  private GrooveRings() {
    ForEach(GROOVE_PERCENTS, (p: number) => {
      Column()
        .width(`${p}%`)
        .aspectRatio(1)
        .borderRadius('50%')
        .border({ width: 0.5, color: VINYL_GROOVE_COLOR })
    }, (p: number) => `${p}`)
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // ① 黑色唱片盘（静止）+ 微弱高光
      Column()
        .width('100%')
        .aspectRatio(1)
        .borderRadius('50%')
        .backgroundColor(VINYL_DISC_COLOR)
        .linearGradient({
          angle: 135,
          colors: [['rgba(255, 255, 255, 0.06)', 0.0], ['rgba(255, 255, 255, 0.0)', 0.45]]
        })

      // 刻槽同心环（静止，叠在盘面上）
      this.GrooveRings()

      // ② 圆形封面标签（旋转）
      Image(this.coverUrl)
        .width('70%')
        .aspectRatio(1)
        .borderRadius('50%')
        .objectFit(ImageFit.Cover)
        .clip(true)
        .rotate({ angle: this.coverAngle })

      // ③ 中心 spindle 小孔（静止）
      Column()
        .width(VINYL_CENTER_HOLE_VP)
        .height(VINYL_CENTER_HOLE_VP)
        .borderRadius('50%')
        .backgroundColor(VINYL_HOLE_COLOR)
    }
    .width(this.discPercent)
    .aspectRatio(1)
    .shadow(ShadowStyle.OUTER_DEFAULT_MD)
  }
}
