import common from '@ohos.app.ability.common';
import { HttpClient } from '../../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL } from '../../../../common/network/ApiConfig';
import { SessionStore } from '../../../../common/storage/SessionStore';
import { ArtistSublistResponse, FollowResponse } from '../../domain/model/MineModels';

export class ArtistSublistApi {
  private httpClient: HttpClient;

  constructor(context: common.UIAbilityContext) {
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL, new SessionStore(context));
  }

  async getArtistSublist(limit: number = 25, offset: number = 0): Promise<ArtistSublistResponse> {
    return this.httpClient.post<ArtistSublistResponse>(
      `/artist/sublist?limit=${limit}&offset=${offset}&timestamp=${Date.now()}`
    );
  }

  async follow(artistId: number, follow: boolean = true): Promise<FollowResponse> {
    const t = follow ? 1 : 0;
    return this.httpClient.post<FollowResponse>(`/artist/sub?id=${artistId}&t=${t}&timestamp=${Date.now()}`);
  }

  private static subscribedIds: Set<number> = new Set();

  static setSubscribedIds(ids: number[]): void {
    ArtistSublistApi.subscribedIds = new Set(ids);
  }

  static addSubscribedId(id: number): void {
    ArtistSublistApi.subscribedIds.add(id);
  }

  static removeSubscribedId(id: number): void {
    ArtistSublistApi.subscribedIds.delete(id);
  }

  static isSubscribed(id: number): boolean {
    return ArtistSublistApi.subscribedIds.has(id);
  }

  static clearSubscribedIds(): void {
    ArtistSublistApi.subscribedIds = new Set();
  }
}
