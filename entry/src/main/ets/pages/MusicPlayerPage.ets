import { router } from '@kit.ArkUI';
import { MusicPlayerCard } from '../features/music/ui/component/MusicPlayerCard';

@Entry
@Component
struct MusicPlayerPage {
  @State private songId: number = 1969519579;

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>;
    const rawSongId = params['songId'];
    if (typeof rawSongId === 'number') {
      this.songId = rawSongId;
      return;
    }
    if (typeof rawSongId === 'string') {
      const parsed = Number.parseInt(rawSongId, 10);
      if (!Number.isNaN(parsed)) {
        this.songId = parsed;
      }
    }
  }

  build() {
    Column({ space: 16 }) {
      Row() {
        Button() {
          Image($r('app.media.ic_arrow_back'))
            .width(18)
            .height(18)
        }
          .type(ButtonType.Circle)
          .width(36)
          .height(36)
          .backgroundColor('#eceff3')
          .onClick(() => {
            router.back();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      MusicPlayerCard({ songId: this.songId });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
  }
}
