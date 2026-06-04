import { HttpClient } from '../../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL } from '../../../../common/network/ApiConfig';
import { BannerResponse } from '../../domain/model/BannerModels';

interface BannerRequest {
  type: number;
}

export class BannerApi {
  private httpClient: HttpClient;

  constructor() {
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL);
  }

  async getBanners(): Promise<BannerResponse> {
    const body: BannerRequest = { type: 0 };
    return this.httpClient.post<BannerResponse>('/banner', body);
  }
}
