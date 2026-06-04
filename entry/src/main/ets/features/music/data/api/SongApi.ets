import { HttpClient } from '../../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL } from '../../../../common/network/ApiConfig';
import { LyricResponse, SongDetailResponse, SongUrlResponse } from '../../domain/model/SongModels';

interface SongUrlRequest {
  id: number;
}

interface SongDetailRequest {
  ids: string;
}

interface LyricRequest {
  id: number;
}

export class SongApi {
  private httpClient: HttpClient;

  constructor() {
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL);
  }

  private buildPath(path: string): string {
    const separator = path.includes('?') ? '&' : '?';
    return `${path}${separator}timestamp=${Date.now()}`;
  }

  async getSongUrl(songId: number): Promise<SongUrlResponse> {
    const body: SongUrlRequest = { id: songId };
    return this.httpClient.post<SongUrlResponse>(this.buildPath('/song/url'), body);
  }

  async getSongDetail(songId: number): Promise<SongDetailResponse> {
    const body: SongDetailRequest = { ids: `${songId}` };
    return this.httpClient.post<SongDetailResponse>(this.buildPath('/song/detail'), body);
  }

  async getLyric(songId: number): Promise<LyricResponse> {
    const body: LyricRequest = { id: songId };
    return this.httpClient.post<LyricResponse>(this.buildPath('/lyric/new'), body);
  }
}
