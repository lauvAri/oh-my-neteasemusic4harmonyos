import { SongDetail, SongPrivilege } from '../model/SongModels';

export interface SongRepository {
  getSongPlayUrl(songId: number): Promise<string>;
  getSongDetail(songId: number): Promise<SongDetail>;
  getSongPrivilege(songId: number): Promise<SongPrivilege | null>;
}
