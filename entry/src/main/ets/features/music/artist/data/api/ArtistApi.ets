import common from '@ohos.app.ability.common';
import { HttpClient } from '../../../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL } from '../../../../../common/network/ApiConfig';
import { SessionStore } from '../../../../../common/storage/SessionStore';
import { ArtistDetailResponse, ArtistSongsResponse, ArtistAlbumsResponse } from '../../domain/model/ArtistModels';

export class ArtistApi {
  private httpClient: HttpClient;

  constructor(context: common.UIAbilityContext) {
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL, new SessionStore(context));
  }

  async getArtistDetail(id: number): Promise<ArtistDetailResponse> {
    return this.httpClient.post<ArtistDetailResponse>(`/artist/detail?id=${id}&timestamp=${Date.now()}`);
  }

  async getArtistSongs(id: number, order: string = 'hot', limit: number = 50,
    offset: number = 0): Promise<ArtistSongsResponse> {
    return this.httpClient.post<ArtistSongsResponse>(
      `/artist/songs?id=${id}&order=${order}&limit=${limit}&offset=${offset}&timestamp=${Date.now()}`
    );
  }

  async getArtistAlbums(id: number, limit: number = 30,
    offset: number = 0): Promise<ArtistAlbumsResponse> {
    return this.httpClient.post<ArtistAlbumsResponse>(
      `/artist/album?id=${id}&limit=${limit}&offset=${offset}&timestamp=${Date.now()}`
    );
  }
}
