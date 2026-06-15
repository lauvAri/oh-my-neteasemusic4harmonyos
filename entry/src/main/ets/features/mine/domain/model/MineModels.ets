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

export interface UserPlaylistSublist {
  playlist: UserPlaylistItem[];
  more: boolean;
  count: number;
}

export interface UserPlaylistSublistResponse {
  code: number;
  data: UserPlaylistSublist;
}

export interface CreatedPlaylist {
  id: number;
  name: string;
  coverImgUrl: string;
  trackCount: number;
  playCount: number;
  privacy: number;
}

export interface CreatePlaylistResponse {
  code: number;
  id: number;
  playlist: CreatedPlaylist;
  message?: string;
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
  alias?: string[];
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
  alias?: string[];
  mvSize?: number;
}

export interface ArtistSublistResponse {
  code: number;
  data: SubscribedArtistItem[];
  hasMore: boolean;
}

export interface FollowResponse {
  code: number;
  message?: string;
}
