import { Banner } from '../model/BannerModels';
import { BannerRepository } from '../repository/BannerRepository';

export class GetBannersUseCase {
  private repository: BannerRepository;

  constructor(repository: BannerRepository) {
    this.repository = repository;
  }

  async execute(): Promise<Banner[]> {
    return this.repository.getBanners();
  }
}
