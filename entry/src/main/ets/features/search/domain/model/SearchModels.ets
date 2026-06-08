export type SearchType = 'song' | 'album' | 'artist' | 'playlist';

export interface SearchTypeOption {
  type: SearchType;
  label: string;
  apiType: number;
}

export const SEARCH_TYPE_OPTIONS: SearchTypeOption[] = [
  { type: 'song', label: '单曲', apiType: 1 },
  { type: 'album', label: '专辑', apiType: 10 },
  { type: 'artist', label: '歌手', apiType: 100 },
  { type: 'playlist', label: '歌单', apiType: 1000 }
];

export interface SearchSongArtist {
  id: number;
  name: string | null;
}

export interface SearchSongAlbum {
  id: number;
  name: string | null;
  picUrl?: string | null;
  picId?: number;
}

export interface SearchSongItem {
  id: number;
  name: string;
  artists: SearchSongArtist[];
  album: SearchSongAlbum;
  duration: number;
  fee?: number;
  mark?: number;
  status?: number;
  mvid?: number;
}

export interface SearchSongResult {
  songs: SearchSongItem[];
  hasMore: boolean;
  songCount: number;
}

export interface SearchSongResponse {
  code: number;
  result: SearchSongResult;
}

export interface SearchAlbumArtist {
  id: number;
  name: string | null;
  picUrl?: string | null;
}

export interface SearchAlbumItem {
  id: number;
  name: string;
  picUrl: string;
  artist: SearchAlbumArtist;
  artists: SearchAlbumArtist[];
  size: number;
  publishTime: number;
  company?: string | null;
  description?: string | null;
  alias?: string[];
  type?: string | null;
  paid?: boolean;
  onSale?: boolean;
}

export interface SearchAlbumResult {
  albums: SearchAlbumItem[];
  albumCount: number;
}

export interface SearchAlbumResponse {
  code: number;
  result: SearchAlbumResult;
}

export interface SearchArtistItem {
  id: number;
  name: string;
  picUrl: string;
  alias: string[];
  albumSize: number;
  musicSize: number;
  mvSize?: number;
  fansSize?: number;
  trans?: string | null;
  img1v1Url?: string;
}

export interface SearchArtistResult {
  artists: SearchArtistItem[];
  hasMore: boolean;
  artistCount: number;
}

export interface SearchArtistResponse {
  code: number;
  result: SearchArtistResult;
}

export interface SearchPlaylistCreator {
  nickname: string;
  userId: number;
  avatarUrl?: string | null;
}

export interface SearchPlaylistItem {
  id: number;
  name: string;
  coverImgUrl: string;
  creator: SearchPlaylistCreator;
  trackCount: number;
  playCount: number;
  bookCount?: number;
  description?: string | null;
  highQuality?: boolean;
  specialType?: number;
  officialPlaylistTitle?: string | null;
}

export interface SearchPlaylistResult {
  playlists: SearchPlaylistItem[];
  hasMore: boolean;
  playlistCount: number;
}

export interface SearchPlaylistResponse {
  code: number;
  result: SearchPlaylistResult;
}
