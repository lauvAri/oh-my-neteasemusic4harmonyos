import common from '@ohos.app.ability.common';
import { HttpClient } from '../../../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL } from '../../../../../common/network/ApiConfig';
import { SessionStore } from '../../../../../common/storage/SessionStore';
import { PlaylistDetailResponse } from '../../domain/model/PlaylistDetailModels';

export class PlaylistDetailApi {
  private httpClient: HttpClient;

  constructor(context: common.UIAbilityContext) {
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL, new SessionStore(context));
  }

  async getPlaylistDetail(playlistId: number): Promise<PlaylistDetailResponse> {
    return this.httpClient.post<PlaylistDetailResponse>(`/playlist/detail?id=${playlistId}`);
  }
}
