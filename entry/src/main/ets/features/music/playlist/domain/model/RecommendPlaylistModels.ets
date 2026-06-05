export interface RecommendPlaylistCreator {
  nickname: string;
}

export interface RecommendPlaylist {
  id: number;
  type: number;
  name: string;
  copywriter: string;
  picUrl: string;
  playcount: number;
  createTime: number;
  trackCount: number;
  userId: number;
  alg: string;
  creator: RecommendPlaylistCreator;
}

export interface RecommendPlaylistResponse {
  code: number;
  featureFirst: boolean;
  haveRcmdSongs: boolean;
  recommend: RecommendPlaylist[];
}
