import { SongAlbum, SongArtist } from './SongModels';

export interface Song {
  id: number;
  name: string;
  ar: SongArtist[];
  al: SongAlbum;
  dt: number;
  reason?: string;
  recommendReason?: string;
}
