import { Song } from './Song';

export interface DailyRecommendData {
  dailySongs: Song[];
}

export interface DailyRecommendResponse {
  code: number;
  data: DailyRecommendData;
}
