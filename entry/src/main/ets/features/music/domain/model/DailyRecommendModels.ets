export interface RecommendArtist {
  id: number;
  name: string;
}

export interface RecommendAlbum {
  id: number;
  name: string;
  picUrl: string;
}

export interface DailyRecommendSong {
  id: number;
  name: string;
  ar: RecommendArtist[];
  al: RecommendAlbum;
  dt: number;
  reason?: string;
  recommendReason?: string;
}

export interface DailyRecommendData {
  dailySongs: DailyRecommendSong[];
}

export interface DailyRecommendResponse {
  code: number;
  data: DailyRecommendData;
}
