export interface SongArtist {
  id: number;
  name: string;
}

export interface SongAlbum {
  id: number;
  name: string;
  picUrl: string;
}

export interface SongDetail {
  id: number;
  name: string;
  t: number;
  fee: number;
  dt: number;
  pop: number;
  publishTime: number;
  alia: string[];
  ar: SongArtist[];
  al: SongAlbum;
}

export interface SongPrivilege {
  id: number;
  st: number;
  fee: number;
  toast: boolean;
  plLevel: string;
  dlLevel: string;
  flLevel: string;
  maxBrLevel: string;
}

export interface SongDetailResponse {
  code: number;
  songs: SongDetail[];
  privileges: SongPrivilege[];
}

export interface SongDetailCachedAggregate {
  detail: SongDetail;
  privilege: SongPrivilege | null;
}

export interface SongUrlItem {
  id: number;
  url: string;
  code: number;
}

export interface SongUrlResponse {
  code: number;
  data: SongUrlItem[];
}

export interface LyricSection {
  version: number;
  lyric: string;
}

export interface LyricResponse {
  code: number;
  lrc?: LyricSection;
  yrc?: LyricSection;
  tlyric?: LyricSection;
}
