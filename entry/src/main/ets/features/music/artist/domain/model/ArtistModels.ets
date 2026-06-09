import { Song } from '../../../domain/model/Song';

export interface ArtistInfo {
  id: number;
  name: string;
  cover: string;
  avatar: string;
  albumSize: number;
  musicSize: number;
  briefDesc: string;
}

export interface ArtistDetailData {
  artist: ArtistInfo;
}

export interface ArtistDetailResponse {
  code: number;
  data: ArtistDetailData;
}

export interface ArtistSongsResponse {
  code: number;
  songs: Song[];
  total: number;
  more: boolean;
}

export interface ArtistAlbumArtist {
  id: number;
  name: string;
}

export interface ArtistAlbumItem {
  id: number;
  name: string;
  picUrl: string;
  artist: ArtistAlbumArtist;
  size: number;
  type: string;
  publishTime: number;
}

export interface ArtistAlbumsResponse {
  code: number;
  hotAlbums: ArtistAlbumItem[];
  more: boolean;
}
