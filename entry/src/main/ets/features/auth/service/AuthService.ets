import common from '@ohos.app.ability.common';
import { HttpClient } from '../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL, NETEASE_PATH_REGISTER_ANONYMous } from '../../../common/network/ApiConfig';
import { SessionStore } from '../../../common/storage/SessionStore';

export interface QrKeyResponse {
  code: number;
  data: QrKeyData;
}

export interface QrKeyData {
  code: number;
  unikey: string;
}

export interface QrCreateResponse {
  code: number;
  data: QrCreateData;
}

export interface QrCreateData {
  qrurl: string;
  qrimg: string;
}

export interface QrLoginSession {
  key: string;
  qrurl: string;
  qrimg: string;
}

export interface QrCheckResponse {
  code: number;
  message?: string;
  cookie?: string;
}

export interface AccountInfo {
  id: number;
  userName: string;
  type: number;
  status: number;
  vipType: number;
}

export interface UserProfile {
  userId: number;
  nickname: string;
  avatarUrl: string;
  backgroundUrl: string;
  signature?: string;
  userName: string;
  gender: number;
  vipType: number;
  followeds?: number;
  follows?: number;
}

export interface UserAccountResponse {
  code: number;
  account: AccountInfo;
  profile: UserProfile;
}

export interface AnonymousResponse {
  code: number;
}

export interface AnonymousLoginResult {
  status: number;
  cookieHeader: string;
  nmtId: string;
}

const NMTID_NAME: string = 'NMTID';

export class AuthService {
  private httpClient: HttpClient;
  private sessionStore?: SessionStore;

  constructor(context?: common.UIAbilityContext) {
    this.sessionStore = context === undefined ? undefined : new SessionStore(context);
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL, this.sessionStore);
  }

  async createQrLogin(): Promise<QrLoginSession> {
    const keyResponse = await this.httpClient.postWithoutCookie<QrKeyResponse>(
      `/login/qr/key?timestamp=${Date.now()}`
    );
    const qrResponse = await this.httpClient.postWithoutCookie<QrCreateResponse>(
      `/login/qr/create?key=${encodeURIComponent(keyResponse.data.unikey)}&qrimg=true&timestamp=${Date.now()}`
    );
    return {
      key: keyResponse.data.unikey,
      qrurl: qrResponse.data.qrurl,
      qrimg: qrResponse.data.qrimg
    };
  }

  async checkQrLogin(key: string): Promise<QrCheckResponse> {
    const response = await this.httpClient.postWithSuccessCodesWithoutCookie<QrCheckResponse>(
      `/login/qr/check?key=${encodeURIComponent(key)}&timestamp=${Date.now()}&noCookie=true`,
      undefined,
      [800, 801, 802, 803]
    );
    if (response.code === 803 && response.cookie !== undefined && response.cookie.length > 0) {
      await this.saveCookie(response.cookie);
    }
    return response;
  }

  async getAccountInfo(): Promise<UserAccountResponse> {
    return this.httpClient.post<UserAccountResponse>(`/user/account?timestamp=${Date.now()}`);
  }

  async loginAnonymously(): Promise<AnonymousLoginResult | null> {
    try {
      const response = await this.httpClient.getWithHeaders<AnonymousResponse>(
        NETEASE_PATH_REGISTER_ANONYMous,
        [200, 400] // 400 是文档约定的"成功"标记,NMTID 通过 Set-Cookie 头下发
      );

      const raw = response.headers['set-cookie'] ?? response.headers['Set-Cookie'];
      const cookieLines: string[] = Array.isArray(raw) ? raw : (raw !== undefined ? [raw] : []);

      const nmtidLine: string | undefined = cookieLines
        .find((line: string) => line.trim().startsWith(`${NMTID_NAME}=`));

      if (nmtidLine === undefined) {
        console.warn('loginAnonymously: NMTID not found in Set-Cookie header');
        return null;
      }

      const semicolonIndex: number = nmtidLine.indexOf(';');
      const bareCookie: string = semicolonIndex === -1
        ? nmtidLine.trim()
        : nmtidLine.substring(0, semicolonIndex).trim();

      if (this.sessionStore !== undefined) {
        await this.sessionStore.saveCookie(bareCookie);
      }

      return {
        status: response.data.code,
        cookieHeader: bareCookie,
        nmtId: bareCookie.substring(NMTID_NAME.length + 1)
      };
    } catch (error) {
      console.warn(`loginAnonymously failed: ${(error as Error).message}`);
      return null;
    }
  }

  async getCookie(): Promise<string> {
    if (this.sessionStore === undefined) {
      return '';
    }
    return this.sessionStore.getCookie();
  }

  async saveCookie(cookie: string): Promise<void> {
    if (this.sessionStore === undefined) {
      return;
    }
    return this.sessionStore.saveCookie(cookie);
  }

  async clearCookie(): Promise<void> {
    if (this.sessionStore === undefined) {
      return;
    }
    return this.sessionStore.clearCookie();
  }
}
