import common from '@ohos.app.ability.common';
import { HttpClient } from '../../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL } from '../../../../common/network/ApiConfig';
import { SessionStore } from '../../../../common/storage/SessionStore';
import { AlbumSublistResponse, FollowResponse } from '../../domain/model/MineModels';

export class AlbumSublistApi {
  private httpClient: HttpClient;

  constructor(context: common.UIAbilityContext) {
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL, new SessionStore(context));
  }

  async getAlbumSublist(limit: number = 25, offset: number = 0): Promise<AlbumSublistResponse> {
    return this.httpClient.post<AlbumSublistResponse>(`/album/sublist?limit=${limit}&offset=${offset}`);
  }

  async subscribe(albumId: number, subscribe: boolean = true): Promise<FollowResponse> {
    const t = subscribe ? 1 : 0;
    return this.httpClient.post<FollowResponse>(`/album/sub?id=${albumId}&t=${t}`);
  }

  private static subscribedIds: Set<number> = new Set();

  static setSubscribedIds(ids: number[]): void {
    AlbumSublistApi.subscribedIds = new Set(ids);
  }

  static addSubscribedId(id: number): void {
    AlbumSublistApi.subscribedIds.add(id);
  }

  static removeSubscribedId(id: number): void {
    AlbumSublistApi.subscribedIds.delete(id);
  }

  static isSubscribed(id: number): boolean {
    return AlbumSublistApi.subscribedIds.has(id);
  }
}
