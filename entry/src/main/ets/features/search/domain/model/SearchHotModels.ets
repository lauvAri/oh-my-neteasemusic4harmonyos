export interface SearchHotDetailItem {
  score: number;
  iconType: number;
  searchWord: string;
  source: number;
  iconUrl: string | null;
  content: string | null;
  url: string | null;
}

export interface SearchHotDetailResponse {
  code: number;
  data: SearchHotDetailItem[];
  message: string;
}
