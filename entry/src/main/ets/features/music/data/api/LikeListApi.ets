import common from '@ohos.app.ability.common';
import { HttpClient } from '../../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL } from '../../../../common/network/ApiConfig';
import { SessionStore } from '../../../../common/storage/SessionStore';

export interface LikeListResponse {
  ids: number[];
  checkPoint: number;
  code: number;
}

export class LikeListApi {
  private httpClient: HttpClient;

  constructor(context: common.UIAbilityContext) {
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL, new SessionStore(context));
  }

  async getLikedSongIds(uid: number): Promise<number[]> {
    const response = await this.httpClient.post<LikeListResponse>(`/likelist?uid=${uid}`);
    return response.ids ?? [];
  }
}