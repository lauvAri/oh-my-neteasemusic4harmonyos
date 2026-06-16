import common from '@ohos.app.ability.common';
import { HttpClient } from '../../../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL } from '../../../../../common/network/ApiConfig';
import { SessionStore } from '../../../../../common/storage/SessionStore';
import { ToplistResponse } from '../../domain/model/ToplistModels';

export class ToplistApi {
  private httpClient: HttpClient;

  constructor(context: common.UIAbilityContext) {
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL, new SessionStore(context));
  }

  async getToplist(): Promise<ToplistResponse> {
    return this.httpClient.post<ToplistResponse>(`/toplist?timestamp=${Date.now()}`);
  }
}
