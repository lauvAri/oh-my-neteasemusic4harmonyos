import { Banner } from '../model/BannerModels';

export interface BannerRepository {
  getBanners(): Promise<Banner[]>;
}
