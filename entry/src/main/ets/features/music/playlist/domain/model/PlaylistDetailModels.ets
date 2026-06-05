import { Song } from '../../../domain/model/Song';

export interface PlaylistDetailCreator {
  nickname: string;
  avatarUrl: string;
}

export interface PlaylistDetail {
  id: number;
  name: string;
  coverImgUrl: string;
  trackCount: number;
  playCount: number;
  subscribedCount: number;
  description: string;
  tags: string[];
  creator: PlaylistDetailCreator;
  tracks: Song[];
}

export interface PlaylistDetailResponse {
  code: number;
  playlist: PlaylistDetail;
  relatedVideos: null;
}
