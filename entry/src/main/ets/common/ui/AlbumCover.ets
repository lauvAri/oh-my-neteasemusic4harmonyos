const COVER_CORNER_RADIUS_VP: number = 16;
const COVER_SHADOW_RADIUS_VP: number = 24;
const COVER_SHADOW_OFFSET_Y_VP: number = 8;
const COVER_SHADOW_COLOR: string = 'rgba(0, 0, 0, 0.45)';
const COVER_DEFAULT_SIZE: string = '92%';

// 脉动参数
const PULSE_AMPLITUDE: number = 0.012;            // ±1.2%
const PULSE_PERIOD_MS: number = 3600;              // 一个呼吸周期
const PULSE_TICK_MS: number = 50;                  // 20 fps 采样
const PULSE_SETTLE_MS: number = 300;               // 暂停时回弹时长

/**
 * 圆角矩形专辑封面。播放时有极轻微的呼吸式缩放,暂停后回弹静止。
 * 取代旧的旋转黑胶样式。
 */
@Component
export struct AlbumCover {
  @Prop coverUrl: string = '';
  @Prop coverSize: string = COVER_DEFAULT_SIZE;
  @StorageLink('miniPlayerPlaying') @Watch('onPlayingChange') private playing: boolean = false;
  @State private scaleValue: number = 1.0;
  private pulseTimerId: number = -1;
  private pulseStartTime: number = 0;

  aboutToAppear(): void {
    if (this.playing) {
      this.startPulse();
    }
  }

  aboutToDisappear(): void {
    this.stopPulse();
  }

  private onPlayingChange(): void {
    if (this.playing) {
      this.startPulse();
    } else {
      this.stopPulse();
    }
  }

  private startPulse(): void {
    this.stopPulse();
    this.pulseStartTime = Date.now();
    this.pulseTimerId = setInterval(() => {
      const elapsed: number = (Date.now() - this.pulseStartTime) % PULSE_PERIOD_MS;
      const phase: number = elapsed / PULSE_PERIOD_MS;
      this.scaleValue = 1.0 + PULSE_AMPLITUDE * Math.sin(2 * Math.PI * phase);
    }, PULSE_TICK_MS);
  }

  private stopPulse(): void {
    if (this.pulseTimerId !== -1) {
      clearInterval(this.pulseTimerId);
      this.pulseTimerId = -1;
    }
    animateTo({ duration: PULSE_SETTLE_MS, curve: Curve.EaseOut }, () => {
      this.scaleValue = 1.0;
    });
  }

  build() {
    Image(this.coverUrl)
      .width(this.coverSize)
      .aspectRatio(1)
      .borderRadius(COVER_CORNER_RADIUS_VP)
      .objectFit(ImageFit.Cover)
      .clip(true)
      .scale({ x: this.scaleValue, y: this.scaleValue })
      .shadow({
        radius: COVER_SHADOW_RADIUS_VP,
        offsetY: COVER_SHADOW_OFFSET_Y_VP,
        color: COVER_SHADOW_COLOR
      })
  }
}
