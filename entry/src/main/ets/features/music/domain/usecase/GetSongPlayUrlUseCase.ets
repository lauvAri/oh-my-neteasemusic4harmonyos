import { SongRepository } from '../repository/SongRepository';

export class GetSongPlayUrlUseCase {
  private repository: SongRepository;

  constructor(repository: SongRepository) {
    this.repository = repository;
  }

  async execute(songId: number): Promise<string> {
    return this.repository.getSongPlayUrl(songId);
  }
}
