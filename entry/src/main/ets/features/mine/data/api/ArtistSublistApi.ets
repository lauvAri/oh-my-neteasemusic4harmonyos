import common from '@ohos.app.ability.common';
import { HttpClient } from '../../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL } from '../../../../common/network/ApiConfig';
import { SessionStore } from '../../../../common/storage/SessionStore';
import { ArtistSublistResponse } from '../../domain/model/MineModels';

export class ArtistSublistApi {
  private httpClient: HttpClient;

  constructor(context: common.UIAbilityContext) {
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL, new SessionStore(context));
  }

  async getArtistSublist(limit: number = 25, offset: number = 0): Promise<ArtistSublistResponse> {
    return this.httpClient.post<ArtistSublistResponse>(`/artist/sublist?limit=${limit}&offset=${offset}`);
  }
}
