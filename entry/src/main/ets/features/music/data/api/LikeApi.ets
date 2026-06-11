import common from '@ohos.app.ability.common';
import { HttpClient } from '../../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL } from '../../../../common/network/ApiConfig';
import { SessionStore } from '../../../../common/storage/SessionStore';

export interface LikeResponse {
  code: number;
  songs: object[];
  playlistId: number;
}

export class LikeApi {
  private httpClient: HttpClient;

  constructor(context: common.UIAbilityContext) {
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL, new SessionStore(context));
  }

  async like(songId: number): Promise<LikeResponse> {
    return this.httpClient.post<LikeResponse>(`/like?id=${songId}`);
  }

  async unlike(songId: number): Promise<LikeResponse> {
    return this.httpClient.post<LikeResponse>(`/like?id=${songId}&like=false`);
  }
}
