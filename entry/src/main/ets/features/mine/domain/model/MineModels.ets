export interface UserPlaylistCreator {
  nickname: string;
  userId: number;
}

export interface UserPlaylistItem {
  id: number;
  name: string;
  coverImgUrl: string;
  trackCount: number;
  playCount: number;
  creator: UserPlaylistCreator;
}

export interface UserPlaylistResponse {
  code: number;
  playlist: UserPlaylistItem[];
  more: boolean;
}

export interface SubscribedAlbumArtist {
  id: number;
  name: string;
}

export interface SubscribedAlbumItem {
  id: number;
  name: string;
  picUrl: string;
  artist?: SubscribedAlbumArtist;
  size: number;
}

export interface AlbumSublistResponse {
  code: number;
  data: SubscribedAlbumItem[];
  hasMore: boolean;
}

export interface SubscribedArtistItem {
  id: number;
  name: string;
  picUrl: string;
  albumSize: number;
}

export interface ArtistSublistResponse {
  code: number;
  data: SubscribedArtistItem[];
  hasMore: boolean;
}
