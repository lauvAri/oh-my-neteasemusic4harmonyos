import { HttpClient } from '../../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL } from '../../../../common/network/ApiConfig';
import { BannerResponse } from '../../domain/model/BannerModels';

export class BannerApi {
  private httpClient: HttpClient;

  constructor() {
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL);
  }

  async getBanners(): Promise<BannerResponse> {
    return this.httpClient.get<BannerResponse>('/banner?type=0');
  }
}
