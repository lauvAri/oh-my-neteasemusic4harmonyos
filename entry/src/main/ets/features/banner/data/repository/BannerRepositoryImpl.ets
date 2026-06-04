import { BannerApi } from '../api/BannerApi';
import { Banner } from '../../domain/model/BannerModels';
import { BannerRepository } from '../../domain/repository/BannerRepository';

export class BannerRepositoryImpl implements BannerRepository {
  private bannerApi: BannerApi;

  constructor(bannerApi: BannerApi) {
    this.bannerApi = bannerApi;
  }

  async getBanners(): Promise<Banner[]> {
    const response = await this.bannerApi.getBanners();
    return response.banners ?? [];
  }
}
