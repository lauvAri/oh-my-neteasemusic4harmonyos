import http from '@ohos.net.http';
import { ApiException } from '../error/ApiException';

interface ApiResponse {
  code: number;
  message?: string;
  msg?: string;
}

interface HttpHeaders {
  'Content-Type': string;
  Cookie?: string;
}

export interface CookieProvider {
  getCookie: () => Promise<string>;
}

export class HttpClient {
  private baseUrl: string;
  private cookieProvider?: CookieProvider;

  constructor(baseUrl: string, cookieProvider?: CookieProvider) {
    this.baseUrl = baseUrl;
    this.cookieProvider = cookieProvider;
  }

  async get<T extends ApiResponse>(path: string): Promise<T> {
    return this.request<T>(http.RequestMethod.GET, path);
  }

  async post<T extends ApiResponse>(path: string, body?: object): Promise<T> {
    return this.request<T>(http.RequestMethod.POST, path, body);
  }

  async getWithSuccessCodes<T extends ApiResponse>(path: string, successCodes: number[]): Promise<T> {
    return this.request<T>(http.RequestMethod.GET, path, undefined, successCodes);
  }

  private async request<T extends ApiResponse>(
    method: http.RequestMethod,
    path: string,
    body?: object,
    successCodes: number[] = [200]
  ): Promise<T> {
    const request = http.createHttp();
    const url = this.buildUrl(path);

    try {
      const headers = await this.createHeaders();
      const response = await request.request(url, {
        method: method,
        header: headers,
        extraData: body === undefined ? undefined : JSON.stringify(body),
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15000,
        readTimeout: 15000
      });

      const bodyText = typeof response.result === 'string' ? response.result : JSON.stringify(response.result);
      try {
        const parsed = JSON.parse(bodyText) as T;
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

  private async createHeaders(): Promise<HttpHeaders> {
    const headers: HttpHeaders = {
      'Content-Type': 'application/json'
    };
    if (this.cookieProvider) {
      const cookie = await this.cookieProvider.getCookie();
      if (cookie.length > 0) {
        headers.Cookie = cookie;
      }
    }
    return headers;
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
