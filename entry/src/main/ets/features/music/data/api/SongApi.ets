import { HttpClient } from '../../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL } from '../../../../common/network/ApiConfig';
import { SongDetailResponse, SongUrlResponse } from '../../domain/model/SongModels';

export class SongApi {
  private httpClient: HttpClient;

  constructor() {
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL);
  }

  async getSongUrl(songId: number): Promise<SongUrlResponse> {
    return this.httpClient.get<SongUrlResponse>(`/song/url?id=${songId}`);
  }

  async getSongDetail(songId: number): Promise<SongDetailResponse> {
    return this.httpClient.get<SongDetailResponse>(`/song/detail?ids=${songId}`);
  }
}
