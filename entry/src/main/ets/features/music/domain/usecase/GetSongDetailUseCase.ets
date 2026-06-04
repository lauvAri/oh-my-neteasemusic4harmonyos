import { SongRepository } from '../repository/SongRepository';
import { SongDetail, SongPrivilege } from '../model/SongModels';

export interface SongDetailAggregate {
  detail: SongDetail;
  privilege: SongPrivilege | null;
}

export class GetSongDetailUseCase {
  private repository: SongRepository;

  constructor(repository: SongRepository) {
    this.repository = repository;
  }

  async execute(songId: number): Promise<SongDetailAggregate> {
    const detail = await this.repository.getSongDetail(songId);
    const privilege = await this.repository.getSongPrivilege(songId);
    return {
      detail,
      privilege
    };
  }
}
