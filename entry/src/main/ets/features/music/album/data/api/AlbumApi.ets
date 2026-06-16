import common from '@ohos.app.ability.common';
import { HttpClient } from '../../../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL } from '../../../../../common/network/ApiConfig';
import { SessionStore } from '../../../../../common/storage/SessionStore';
import { AlbumDetailResponse } from '../../domain/model/AlbumModels';

export class AlbumApi {
  private httpClient: HttpClient;

  constructor(context: common.UIAbilityContext) {
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL, new SessionStore(context));
  }

  async getAlbumDetail(id: number): Promise<AlbumDetailResponse> {
    return this.httpClient.post<AlbumDetailResponse>(`/album?id=${id}&timestamp=${Date.now()}`);
  }
}
