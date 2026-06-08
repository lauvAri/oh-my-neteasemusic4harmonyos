export interface Toplist {
  id: number;
  name: string;
  coverImgUrl: string;
  updateFrequency: string;
  description: string;
  playCount: number;
  trackCount: number;
}

export interface ArtistToplist {
  name: string;
  coverUrl: string;
  updateFrequency: string;
}

export interface ToplistResponse {
  code: number;
  list: Toplist[];
  artistToplist: ArtistToplist;
}
