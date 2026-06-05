import common from '@ohos.app.ability.common';
import { HttpClient } from '../../../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL } from '../../../../../common/network/ApiConfig';
import { SessionStore } from '../../../../../common/storage/SessionStore';
import { RecommendPlaylistResponse } from '../../domain/model/RecommendPlaylistModels';

export class RecommendPlaylistApi {
  private httpClient: HttpClient;

  constructor(context: common.UIAbilityContext) {
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL, new SessionStore(context));
  }

  async getDailyRecommendResources(): Promise<RecommendPlaylistResponse> {
    return this.httpClient.post<RecommendPlaylistResponse>('/recommend/resource');
  }
}
