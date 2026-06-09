import { Song } from '../../../domain/model/Song';

export interface AlbumArtist {
  id: number;
  name: string;
}

export interface AlbumInfo {
  id: number;
  name: string;
  picUrl: string;
  artist: AlbumArtist;
  size: number;
  publishTime: number;
  description: string;
  company: string;
}

export interface AlbumDetailResponse {
  code: number;
  songs: Song[];
  album: AlbumInfo;
}
