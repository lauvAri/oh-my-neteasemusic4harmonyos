import common from '@ohos.app.ability.common';
import { HttpClient } from '../../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL } from '../../../../common/network/ApiConfig';
import { SessionStore } from '../../../../common/storage/SessionStore';
import { UserPlaylistResponse } from '../../domain/model/MineModels';

export class UserPlaylistApi {
  private httpClient: HttpClient;

  constructor(context: common.UIAbilityContext) {
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL, new SessionStore(context));
  }

  async getUserPlaylist(uid: number, limit: number = 30, offset: number = 0): Promise<UserPlaylistResponse> {
    return this.httpClient.post<UserPlaylistResponse>(`/user/playlist?uid=${uid}&limit=${limit}&offset=${offset}`);
  }
}
