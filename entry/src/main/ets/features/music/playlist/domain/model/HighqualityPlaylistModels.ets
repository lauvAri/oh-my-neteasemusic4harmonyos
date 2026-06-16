export interface HighqualityPlaylistCreator {
  userId: number;
  nickname: string;
}

export interface HighqualityPlaylistItem {
  id: number;
  name: string;
  coverImgUrl: string;
  copywriter: string;
  playCount: number;
  trackCount: number;
  updateTime: number;
  tags: string[];
  creator: HighqualityPlaylistCreator;
}

export interface HighqualityPlaylistResponse {
  code: number;
  playlists: HighqualityPlaylistItem[];
  more: boolean;
  lasttime: number;
  total: number;
}

export interface HighqualityPlaylistTagItem {
  id: number;
  name: string;
  type: number;
  category: number;
  hot: boolean;
}

export interface HighqualityPlaylistTagResponse {
  code: number;
  tags: HighqualityPlaylistTagItem[];
}
