import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { CookieProvider } from '../network/HttpClient';

const PREF_NAME: string = 'auth_session';
const KEY_COOKIE: string = 'cookie';

export class SessionStore implements CookieProvider {
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async saveCookie(cookie: string): Promise<void> {
    const pref = await preferences.getPreferences(this.context, PREF_NAME);
    await pref.put(KEY_COOKIE, cookie);
    await pref.flush();
    console.log('set cookie:', cookie);// debug
  }

  async getCookie(): Promise<string> {
    const pref = await preferences.getPreferences(this.context, PREF_NAME);
    const value = await pref.get(KEY_COOKIE, '');
    console.log('get cookie:', value); // debug
    return value as string;
  }

  async clearCookie(): Promise<void> {
    const pref = await preferences.getPreferences(this.context, PREF_NAME);
    await pref.delete(KEY_COOKIE);
    await pref.flush();
  }
}
