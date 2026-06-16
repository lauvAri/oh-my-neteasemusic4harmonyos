import { AlbumSublistApi } from '../../features/mine/data/api/AlbumSublistApi';
import { ArtistSublistApi } from '../../features/mine/data/api/ArtistSublistApi';
import { PlayerEngine } from '../../features/music/service/PlayerEngine';

export class UserStateCleaner {
  static async clearAll(): Promise<void> {
    AppStorage.setOrCreate<number>('userId', 0);
    AppStorage.setOrCreate<number>('likedPlaylistId', 0);
    AlbumSublistApi.clearSubscribedIds();
    ArtistSublistApi.clearSubscribedIds();
    await PlayerEngine.getInstance().resetSessionUserState();
  }
}
