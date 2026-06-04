import common from '@ohos.app.ability.common';
import { HttpClient } from '../../../common/network/HttpClient';
import { NETEASE_API_BASE_URL } from '../../../common/network/ApiConfig';
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

interface UserAccountRequest {
  cookie: string;
}

export class AuthService {
  private httpClient: HttpClient;
  private sessionStore?: SessionStore;

  constructor(context?: common.UIAbilityContext) {
    this.sessionStore = context === undefined ? undefined : new SessionStore(context);
    this.httpClient = new HttpClient(NETEASE_API_BASE_URL, this.sessionStore);
  }

  async createQrLogin(): Promise<QrLoginSession> {
    const keyResponse = await this.httpClient.get<QrKeyResponse>(`/login/qr/key?timestamp=${Date.now()}`);
    const qrResponse = await this.httpClient.get<QrCreateResponse>(
      `/login/qr/create?key=${encodeURIComponent(keyResponse.data.unikey)}&qrimg=true&timestamp=${Date.now()}`
    );
    return {
      key: keyResponse.data.unikey,
      qrurl: qrResponse.data.qrurl,
      qrimg: qrResponse.data.qrimg
    };
  }

  async checkQrLogin(key: string): Promise<QrCheckResponse> {
    const response = await this.httpClient.getWithSuccessCodes<QrCheckResponse>(
      `/login/qr/check?key=${encodeURIComponent(key)}&timestamp=${Date.now()}`,
      [800, 801, 802, 803]
    );
    if (response.code === 803 && response.cookie !== undefined && response.cookie.length > 0) {
      await this.saveCookie(response.cookie);
    }
    return response;
  }

  async getAccountInfo(): Promise<UserAccountResponse> {
    const cookie = await this.getCookie();
    const body: UserAccountRequest = { cookie: cookie };
    return this.httpClient.post<UserAccountResponse>('/user/account', body);
  }

  async hasValidSession(): Promise<boolean> {
    const cookie = await this.getCookie();
    if (cookie.trim().length === 0) {
      return false;
    }

    try {
      await this.getAccountInfo();
      return true;
    } catch (error) {
      await this.clearCookie();
      return false;
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
