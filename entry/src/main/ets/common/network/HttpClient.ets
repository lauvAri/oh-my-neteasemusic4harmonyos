import http from '@ohos.net.http';
import { ApiException } from '../error/ApiException';

interface ApiResponse {
  code: number;
  message?: string;
  msg?: string;
}

interface HttpHeaders {
  'Content-Type': string;
}

export interface CookieProvider {
  getCookie: () => Promise<string>;
}

interface RequestBody {
  cookie?: string;
}

export class HttpClient {
  private static globalCookieProvider?: CookieProvider;
  private baseUrl: string;
  private cookieProvider?: CookieProvider;

  constructor(baseUrl: string, cookieProvider?: CookieProvider) {
    this.baseUrl = baseUrl;
    this.cookieProvider = cookieProvider;
  }

  static setGlobalCookieProvider(cookieProvider: CookieProvider): void {
    HttpClient.globalCookieProvider = cookieProvider;
  }

  async post<T extends ApiResponse>(path: string, body?: object): Promise<T> {
    return this.request<T>(path, body, [200], true);
  }

  async postWithoutCookie<T extends ApiResponse>(path: string, body?: object): Promise<T> {
    return this.request<T>(path, body, [200], false);
  }

  async postWithSuccessCodesWithoutCookie<T extends ApiResponse>(
    path: string,
    body: object | undefined,
    successCodes: number[]
  ): Promise<T> {
    return this.request<T>(path, body, successCodes, false);
  }

  private async request<T extends ApiResponse>(
    path: string,
    body?: object,
    successCodes: number[] = [200],
    shouldAppendCookie: boolean = true
  ): Promise<T> {
    const request = http.createHttp();
    const url = this.buildUrl(path);

    try {
      const requestBodyText = await this.createBodyText(body, shouldAppendCookie);
      const response = await request.request(url, {
        method: http.RequestMethod.POST,
        header: this.createHeaders(),
        extraData: requestBodyText,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15000,
        readTimeout: 15000
      });

      const responseBodyText = typeof response.result === 'string' ? response.result : JSON.stringify(response.result);
      try {
        const parsed = JSON.parse(responseBodyText) as T;
        if (typeof parsed.code !== 'number') {
          throw ApiException.parse('响应中缺少 code 字段');
        }
        if (!successCodes.includes(parsed.code)) {
          const errorMessage = this.resolveBusinessMessage(parsed);
          throw ApiException.business(parsed.code, errorMessage);
        }
        return parsed;
      } catch (error) {
        if (error instanceof ApiException) {
          throw error;
        }
        throw ApiException.parse((error as Error).message);
      }
    } catch (error) {
      if (error instanceof ApiException) {
        throw error;
      }
      throw ApiException.network((error as Error).message);
    } finally {
      request.destroy();
    }
  }

  private createHeaders(): HttpHeaders {
    return {
      'Content-Type': 'application/json'
    };
  }

  private async createBodyText(body?: object, shouldAppendCookie: boolean = true): Promise<string> {
    const requestBody = (body === undefined ? {} : body) as RequestBody;
    if (shouldAppendCookie) {
      const cookieProvider = this.cookieProvider ?? HttpClient.globalCookieProvider;
      if (cookieProvider !== undefined) {
        const cookie = await cookieProvider.getCookie();
        if (cookie.length > 0) {
          requestBody.cookie = cookie;
        }
      }
    }
    return JSON.stringify(requestBody);
  }

  private buildUrl(path: string): string {
    const normalizedPath = path.startsWith('/') ? path : '/' + path;
    return this.baseUrl + normalizedPath;
  }

  private resolveBusinessMessage(response: ApiResponse): string {
    if (typeof response.message === 'string' && response.message.length > 0) {
      return response.message;
    }
    if (typeof response.msg === 'string' && response.msg.length > 0) {
      return response.msg;
    }
    return '业务请求失败';
  }
}
