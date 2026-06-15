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
  description: string | null;
  subscribed: boolean;
  tags: string[] | null;
  creator: PlaylistDetailCreator;
  tracks: Song[];
}

export interface PlaylistDetailResponse {
  code: number;
  playlist: PlaylistDetail;
  relatedVideos: null;
}
