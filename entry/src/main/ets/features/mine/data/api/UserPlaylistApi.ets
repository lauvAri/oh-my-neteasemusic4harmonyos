import common from '@ohos.app.ability.common';
import { HttpClient } from '../../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL } from '../../../../common/network/ApiConfig';
import { SessionStore } from '../../../../common/storage/SessionStore';
import {
  UserPlaylistResponse,
  UserPlaylistSublistResponse,
  FollowResponse,
  CreatePlaylistResponse,
  PlaylistTagResponse,
  DeletePlaylistResponse,
  UpdatePlaylistResponse,
  UpdatePlaylistParams
} from '../../domain/model/MineModels';

interface PlaylistTracksResponse {
  code: number;
  message?: string;
  msg?: string;
}

interface PlaylistTracksBody {
  code: number;
  message?: string;
  msg?: string;
  count?: number;
  cloudCount?: number;
}

interface PlaylistTracksWrappedResponse {
  status: number;
  body: PlaylistTracksBody;
}

export class UserPlaylistApi {
  private httpClient: HttpClient;

  constructor(context: common.UIAbilityContext) {
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL, new SessionStore(context));
  }

  async getUserPlaylist(uid: number, limit: number = 30, offset: number = 0): Promise<UserPlaylistResponse> {
    return this.httpClient.post<UserPlaylistResponse>(
      `/user/playlist?uid=${uid}&limit=${limit}&offset=${offset}&timestamp=${Date.now()}`
    );
  }

  async getUserCreatedPlaylists(uid: number, limit: number = 30, offset: number = 0): Promise<UserPlaylistSublistResponse> {
    return this.httpClient.post<UserPlaylistSublistResponse>(
      `/user/playlist/create?uid=${uid}&limit=${limit}&offset=${offset}&timestamp=${Date.now()}`
    );
  }

  async getUserCollectedPlaylists(uid: number, limit: number = 30, offset: number = 0): Promise<UserPlaylistSublistResponse> {
    return this.httpClient.post<UserPlaylistSublistResponse>(
      `/user/playlist/collect?uid=${uid}&limit=${limit}&offset=${offset}&timestamp=${Date.now()}`
    );
  }

  async createPlaylist(name: string, isPrivate: boolean): Promise<CreatePlaylistResponse> {
    const privacyQuery = isPrivate ? '&privacy=10' : '';
    return this.httpClient.post<CreatePlaylistResponse>(
      `/playlist/create?name=${encodeURIComponent(name)}${privacyQuery}&timestamp=${Date.now()}`
    );
  }

  async getPlaylistTags(): Promise<PlaylistTagResponse> {
    return this.httpClient.post<PlaylistTagResponse>(`/playlist/highquality/tags?timestamp=${Date.now()}`);
  }

  async deletePlaylist(playlistId: number): Promise<DeletePlaylistResponse> {
    return this.httpClient.post<DeletePlaylistResponse>(`/playlist/delete?id=${playlistId}&timestamp=${Date.now()}`);
  }

  async updatePlaylist(params: UpdatePlaylistParams): Promise<UpdatePlaylistResponse> {
    const path = `/playlist/update?id=${params.id}` +
      `&name=${encodeURIComponent(params.name)}` +
      `&desc=${encodeURIComponent(params.desc)}` +
      `&tags=${encodeURIComponent(params.tags.join(';'))}` +
      `&timestamp=${Date.now()}`;
    return this.httpClient.post<UpdatePlaylistResponse>(path);
  }

  async subscribe(playlistId: number, subscribe: boolean): Promise<FollowResponse> {
    const t = subscribe ? 1 : 2;
    return this.httpClient.post<FollowResponse>(`/playlist/subscribe?t=${t}&id=${playlistId}&timestamp=${Date.now()}`);
  }

  async removeTrackFromPlaylist(playlistId: number, songId: number): Promise<PlaylistTracksResponse> {
    return this.requestPlaylistTracks(
      `/playlist/tracks?op=del&pid=${playlistId}&tracks=${songId}&timestamp=${Date.now()}`
    );
  }

  async addTrackToPlaylist(playlistId: number, songId: number): Promise<PlaylistTracksResponse> {
    return this.requestPlaylistTracks(
      `/playlist/tracks?op=add&pid=${playlistId}&tracks=${songId}&timestamp=${Date.now()}`
    );
  }

  private async requestPlaylistTracks(path: string): Promise<PlaylistTracksResponse> {
    const response = await this.httpClient.postRaw<PlaylistTracksWrappedResponse>(path);
    console.info(`[UserPlaylistApi] playlist tracks response path=${path}, response=${JSON.stringify(response)}`);
    if (response.body === undefined || typeof response.body.code !== 'number') {
      console.error(`[UserPlaylistApi] invalid playlist tracks response path=${path}, body=${JSON.stringify(response.body)}`);
      throw new Error('歌单操作响应格式异常');
    }
    console.info(`[UserPlaylistApi] playlist tracks body code=${response.body.code}, message=${response.body.message ?? ''}, msg=${response.body.msg ?? ''}`);
    if (response.body.code !== 200) {
      throw new Error(this.resolvePlaylistTracksMessage(response.body));
    }
    const result: PlaylistTracksResponse = {
      code: response.body.code,
      message: response.body.message,
      msg: response.body.msg
    };
    return result;
  }

  private resolvePlaylistTracksMessage(body: PlaylistTracksBody): string {
    if (typeof body.message === 'string' && body.message.length > 0) {
      return body.message;
    }
    if (typeof body.msg === 'string' && body.msg.length > 0) {
      return body.msg;
    }
    return '歌单操作失败';
  }
}
