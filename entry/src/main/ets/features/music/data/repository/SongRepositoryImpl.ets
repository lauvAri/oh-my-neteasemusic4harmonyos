import common from '@ohos.app.ability.common';
import { ApiException } from '../../../../common/error/ApiException';
import { SongApi } from '../api/SongApi';
import { LikeApi } from '../api/LikeApi';
import { LikeListApi } from '../api/LikeListApi';
import { SongRepository } from '../../domain/repository/SongRepository';
import {
  LyricResponse,
  SongDetail,
  SongDetailCachedAggregate,
  SongPrivilege
} from '../../domain/model/SongModels';

export class SongRepositoryImpl implements SongRepository {
  private static detailCache: Map<number, SongDetailCachedAggregate> = new Map();
  private static lyricCache: Map<number, LyricResponse> = new Map();
  private static likedSongIds: Set<number> = new Set();

  private songApi: SongApi;
  private likeApi?: LikeApi;

  constructor(songApi: SongApi) {
    this.songApi = songApi;
  }

  setLikeApi(api: LikeApi): void {
    this.likeApi = api;
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
    const cached = SongRepositoryImpl.detailCache.get(songId);
    if (cached) {
      return cached.detail;
    }
    const loaded = await this.loadSongDetailAggregate(songId);
    return loaded.detail;
  }

  async getSongPrivilege(songId: number): Promise<SongPrivilege | null> {
    const cached = SongRepositoryImpl.detailCache.get(songId);
    if (cached) {
      return cached.privilege;
    }
    const loaded = await this.loadSongDetailAggregate(songId);
    return loaded.privilege;
  }

  getCachedDetail(songId: number): SongDetailCachedAggregate | null {
    const cached = SongRepositoryImpl.detailCache.get(songId);
    return cached ?? null;
  }

  async getSongLyric(songId: number): Promise<LyricResponse> {
    const cached = SongRepositoryImpl.lyricCache.get(songId);
    if (cached) {
      return cached;
    }
    const response = await this.songApi.getLyric(songId);
    SongRepositoryImpl.lyricCache.set(songId, response);
    return response;
  }
  async toggleSongLike(songId: number, like: boolean): Promise<void> {
    if (!this.likeApi) {
      throw ApiException.business(-1001, '请先登录');
    }
    if (like) {
      await this.likeApi.like(songId);
    } else {
      await this.likeApi.unlike(songId);
    }
  }

  static addLikedSongId(songId: number): void {
    SongRepositoryImpl.likedSongIds.add(songId);
  }

  static removeLikedSongId(songId: number): void {
    SongRepositoryImpl.likedSongIds.delete(songId);
  }

  static isLikedSong(songId: number): boolean {
    return SongRepositoryImpl.likedSongIds.has(songId);
  }

  static setLikedSongIds(ids: number[]): void {
    SongRepositoryImpl.likedSongIds = new Set(ids);
  }

  async loadLikedSongIds(uid: number, context: common.UIAbilityContext): Promise<void> {
    const likeListApi = new LikeListApi(context);
    const ids = await likeListApi.getLikedSongIds(uid);
    SongRepositoryImpl.setLikedSongIds(ids);
  }

  private async loadSongDetailAggregate(songId: number): Promise<SongDetailCachedAggregate> {
    const response = await this.songApi.getSongDetail(songId);
    const detail = response.songs && response.songs.length > 0 ? response.songs[0] : undefined;
    if (!detail) {
      throw ApiException.business(-4, '未获取到歌曲详情');
    }
    const privilege = response.privileges.find((item: SongPrivilege) => item.id === songId) ?? null;
    const aggregate: SongDetailCachedAggregate = { detail, privilege };
    SongRepositoryImpl.detailCache.set(songId, aggregate);
    return aggregate;
  }
}
