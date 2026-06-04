import { ApiException } from '../../../../common/error/ApiException';
import { SongApi } from '../api/SongApi';
import { SongRepository } from '../../domain/repository/SongRepository';
import { SongDetail, SongDetailCachedAggregate, SongPrivilege } from '../../domain/model/SongModels';

export class SongRepositoryImpl implements SongRepository {
  private songApi: SongApi;
  private detailCache: Map<number, SongDetailCachedAggregate> = new Map();

  constructor(songApi: SongApi) {
    this.songApi = songApi;
  }

  async getSongPlayUrl(songId: number): Promise<string> {
    const response = await this.songApi.getSongUrl(songId);
    const first = response.data && response.data.length > 0 ? response.data[0] : undefined;
    if (!first || !first.url || first.url.length === 0) {
      throw ApiException.business(-3, '未获取到可播放音频链接');
    }
    return first.url;
  }

  async getSongDetail(songId: number): Promise<SongDetail> {
    const cached = this.detailCache.get(songId);
    if (cached) {
      return cached.detail;
    }
    const loaded = await this.loadSongDetailAggregate(songId);
    return loaded.detail;
  }

  async getSongPrivilege(songId: number): Promise<SongPrivilege | null> {
    const cached = this.detailCache.get(songId);
    if (cached) {
      return cached.privilege;
    }
    const loaded = await this.loadSongDetailAggregate(songId);
    return loaded.privilege;
  }

  private async loadSongDetailAggregate(songId: number): Promise<SongDetailCachedAggregate> {
    const response = await this.songApi.getSongDetail(songId);
    const detail = response.songs && response.songs.length > 0 ? response.songs[0] : undefined;
    if (!detail) {
      throw ApiException.business(-4, '未获取到歌曲详情');
    }
    const privilege = response.privileges.find((item: SongPrivilege) => item.id === songId) ?? null;
    const aggregate: SongDetailCachedAggregate = { detail, privilege };
    this.detailCache.set(songId, aggregate);
    return aggregate;
  }
}
