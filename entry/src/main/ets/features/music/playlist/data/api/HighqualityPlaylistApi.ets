import common from '@ohos.app.ability.common';
import { HttpClient } from '../../../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL } from '../../../../../common/network/ApiConfig';
import { SessionStore } from '../../../../../common/storage/SessionStore';
import {
  HighqualityPlaylistResponse,
  HighqualityPlaylistTagResponse
} from '../../domain/model/HighqualityPlaylistModels';

export class HighqualityPlaylistApi {
  private httpClient: HttpClient;

  constructor(context: common.UIAbilityContext) {
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL, new SessionStore(context));
  }

  async getHighqualityPlaylists(
    cat: string = '全部',
    limit: number = 30,
    before: number = 0
  ): Promise<HighqualityPlaylistResponse> {
    let path = `/top/playlist/highquality?cat=${encodeURIComponent(cat)}&limit=${limit}&timestamp=${Date.now()}`;
    if (before > 0) {
      path = `${path}&before=${before}`;
    }
    return this.httpClient.post<HighqualityPlaylistResponse>(path);
  }

  async getHighqualityTags(): Promise<HighqualityPlaylistTagResponse> {
    return this.httpClient.post<HighqualityPlaylistTagResponse>(`/playlist/highquality/tags?timestamp=${Date.now()}`);
  }
}
