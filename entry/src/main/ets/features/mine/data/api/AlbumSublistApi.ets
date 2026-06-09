import common from '@ohos.app.ability.common';
import { HttpClient } from '../../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL } from '../../../../common/network/ApiConfig';
import { SessionStore } from '../../../../common/storage/SessionStore';
import { AlbumSublistResponse } from '../../domain/model/MineModels';

export class AlbumSublistApi {
  private httpClient: HttpClient;

  constructor(context: common.UIAbilityContext) {
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL, new SessionStore(context));
  }

  async getAlbumSublist(limit: number = 25, offset: number = 0): Promise<AlbumSublistResponse> {
    return this.httpClient.post<AlbumSublistResponse>(`/album/sublist?limit=${limit}&offset=${offset}`);
  }
}
