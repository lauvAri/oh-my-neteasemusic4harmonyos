import common from '@ohos.app.ability.common';
import { HttpClient } from '../../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL } from '../../../../common/network/ApiConfig';
import { SessionStore } from '../../../../common/storage/SessionStore';
import {
  UserPlaylistResponse,
  UserPlaylistSublistResponse,
  FollowResponse,
  CreatePlaylistResponse
} from '../../domain/model/MineModels';

export class UserPlaylistApi {
  private httpClient: HttpClient;

  constructor(context: common.UIAbilityContext) {
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL, new SessionStore(context));
  }

  async getUserPlaylist(uid: number, limit: number = 30, offset: number = 0): Promise<UserPlaylistResponse> {
    return this.httpClient.post<UserPlaylistResponse>(`/user/playlist?uid=${uid}&limit=${limit}&offset=${offset}`);
  }

  async getUserCreatedPlaylists(uid: number, limit: number = 30, offset: number = 0): Promise<UserPlaylistSublistResponse> {
    return this.httpClient.post<UserPlaylistSublistResponse>(`/user/playlist/create?uid=${uid}&limit=${limit}&offset=${offset}`);
  }

  async getUserCollectedPlaylists(uid: number, limit: number = 30, offset: number = 0): Promise<UserPlaylistSublistResponse> {
    return this.httpClient.post<UserPlaylistSublistResponse>(`/user/playlist/collect?uid=${uid}&limit=${limit}&offset=${offset}`);
  }

  async createPlaylist(name: string, isPrivate: boolean): Promise<CreatePlaylistResponse> {
    const privacyQuery = isPrivate ? '&privacy=10' : '';
    return this.httpClient.post<CreatePlaylistResponse>(
      `/playlist/create?name=${encodeURIComponent(name)}${privacyQuery}`
    );
  }

  async subscribe(playlistId: number, subscribe: boolean): Promise<FollowResponse> {
    const t = subscribe ? 1 : 2;
    return this.httpClient.post<FollowResponse>(`/playlist/subscribe?t=${t}&id=${playlistId}`);
  }
}
