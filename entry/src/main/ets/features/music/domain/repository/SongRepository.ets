import { SongDetail, SongDetailCachedAggregate, SongPrivilege, LyricResponse } from '../model/SongModels';

export interface SongRepository {
  getSongPlayUrl(songId: number): Promise<string>;
  getSongDetail(songId: number): Promise<SongDetail>;
  getSongPrivilege(songId: number): Promise<SongPrivilege | null>;
  getCachedDetail(songId: number): SongDetailCachedAggregate | null;
  getSongLyric(songId: number): Promise<LyricResponse>;
}
