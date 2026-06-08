import common from '@ohos.app.ability.common';
import { HttpClient } from '../../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL } from '../../../../common/network/ApiConfig';
import { SessionStore } from '../../../../common/storage/SessionStore';
import {
  SearchSongResponse,
  SearchAlbumResponse,
  SearchArtistResponse,
  SearchPlaylistResponse
} from '../../domain/model/SearchModels';

export class SearchApi {
  private httpClient: HttpClient;

  constructor(context: common.UIAbilityContext) {
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL, new SessionStore(context));
  }

  private buildPath(keywords: string, type: number, offset: number, limit: number): string {
    const encoded = encodeURIComponent(keywords);
    return `/search?keywords=${encoded}&type=${type}&offset=${offset}&limit=${limit}`;
  }

  async searchSongs(keywords: string, offset: number, limit: number): Promise<SearchSongResponse> {
    return this.httpClient.post<SearchSongResponse>(this.buildPath(keywords, 1, offset, limit));
  }

  async searchAlbums(keywords: string, offset: number, limit: number): Promise<SearchAlbumResponse> {
    return this.httpClient.post<SearchAlbumResponse>(this.buildPath(keywords, 10, offset, limit));
  }

  async searchArtists(keywords: string, offset: number, limit: number): Promise<SearchArtistResponse> {
    return this.httpClient.post<SearchArtistResponse>(this.buildPath(keywords, 100, offset, limit));
  }

  async searchPlaylists(keywords: string, offset: number, limit: number): Promise<SearchPlaylistResponse> {
    return this.httpClient.post<SearchPlaylistResponse>(this.buildPath(keywords, 1000, offset, limit));
  }
}
