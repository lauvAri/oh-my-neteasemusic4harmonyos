import common from '@ohos.app.ability.common';
import { HttpClient } from '../../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL } from '../../../../common/network/ApiConfig';
import { SessionStore } from '../../../../common/storage/SessionStore';
import { SearchHotDetailResponse } from '../../domain/model/SearchHotModels';

export class SearchHotApi {
  private httpClient: HttpClient;

  constructor(context: common.UIAbilityContext) {
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL, new SessionStore(context));
  }

  async getHotDetail(): Promise<SearchHotDetailResponse> {
    return this.httpClient.post<SearchHotDetailResponse>('/search/hot/detail');
  }
}
