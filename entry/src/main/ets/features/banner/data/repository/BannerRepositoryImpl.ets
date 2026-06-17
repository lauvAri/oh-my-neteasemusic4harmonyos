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
    const banners: Banner[] = response.banners ?? [];
    // 只保留 orpheus:// 站内跳转,过滤 https:// 等外链,避免跳到 music.163.com H5
    return banners.filter((banner: Banner): boolean =>
      typeof banner.url === 'string' && banner.url.toLowerCase().startsWith('orpheus://')
    );
  }
}
