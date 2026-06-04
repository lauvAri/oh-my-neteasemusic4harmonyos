export class ApiException extends Error {
  code: number;
  detail: string;

  constructor(code: number, message: string, detail: string = '') {
    super(message);
    this.code = code;
    this.detail = detail;
  }

  static network(message: string): ApiException {
    return new ApiException(-1, '网络请求失败', message);
  }

  static parse(message: string): ApiException {
    return new ApiException(-2, '响应解析失败', message);
  }

  static business(code: number, message: string): ApiException {
    return new ApiException(code, message);
  }
}
