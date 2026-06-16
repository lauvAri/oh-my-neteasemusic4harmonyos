export type OrpheusAction =
  | 'song'
  | 'album'
  | 'artist'
  | 'playlist'
  | 'web'
  | 'download'
  | 'unsupported';

export interface OrpheusRoute {
  handled: boolean;
  action: OrpheusAction;
  targetId: number;
  httpUrl?: string;
}

const ORPHEUS_SONG_PREFIX: string = 'orpheus://song/';
const ORPHEUS_ALBUM_PREFIX: string = 'orpheus://album/';
const ORPHEUS_ARTIST_PREFIX: string = 'orpheus://artist/';
const ORPHEUS_PLAYLIST_PREFIX: string = 'orpheus://playlist/';

const NeteaseDownloadHosts: string[] = [
  'music.163.com',
  'y.music.163.com',
  'interface.music.163.com'
];

function isNeteaseDownloadPath(lowerPath: string): boolean {
  if (lowerPath === '/download') {
    return true;
  }
  if (lowerPath === '/m/download') {
    return true;
  }
  if (lowerPath.startsWith('/api/mobile/download')) {
    return true;
  }
  if (lowerPath.startsWith('/api/package/download/')) {
    return true;
  }
  return false;
}

function matchNeteaseDownloadUrl(lower: string): boolean {
  const marker: number = lower.indexOf('://');
  if (marker < 0) {
    return false;
  }
  const scheme: string = lower.slice(0, marker);
  if (scheme !== 'http' && scheme !== 'https') {
    return false;
  }
  const rest: string = lower.slice(marker + 3);
  const pathIdx: number = rest.search(/[/?#]/);
  const host: string = pathIdx >= 0 ? rest.slice(0, pathIdx) : rest;
  if (NeteaseDownloadHosts.indexOf(host) < 0) {
    return false;
  }
  const pathIdx2: number = rest.indexOf('?');
  const hashIdx: number = rest.indexOf('#');
  let endIdx: number = rest.length;
  if (pathIdx2 >= 0 && pathIdx2 < endIdx) {
    endIdx = pathIdx2;
  }
  if (hashIdx >= 0 && hashIdx < endIdx) {
    endIdx = hashIdx;
  }
  const startIdx: number = pathIdx >= 0 ? pathIdx : rest.length;
  const path: string = rest.slice(startIdx, endIdx).toLowerCase();
  return isNeteaseDownloadPath(path);
}

export class OrpheusUrlRouter {
  static parse(rawUrl: string): OrpheusRoute {
    if (rawUrl === undefined || rawUrl === null || rawUrl.length === 0) {
      return { handled: false, action: 'unsupported', targetId: 0 };
    }
    const lower: string = rawUrl.toLowerCase();
    if (matchNeteaseDownloadUrl(lower)) {
      return { handled: true, action: 'download', targetId: 0, httpUrl: rawUrl };
    }

    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return { handled: true, action: 'web', targetId: 0, httpUrl: rawUrl };
    }

    if (lower.startsWith(ORPHEUS_SONG_PREFIX)) {
      const id: number = parseTrailingId(rawUrl, ORPHEUS_SONG_PREFIX.length);
      return { handled: id > 0, action: 'song', targetId: id };
    }

    if (lower.startsWith(ORPHEUS_ALBUM_PREFIX)) {
      const id: number = parseTrailingId(rawUrl, ORPHEUS_ALBUM_PREFIX.length);
      return { handled: id > 0, action: 'album', targetId: id };
    }
    if (lower.startsWith(ORPHEUS_ARTIST_PREFIX)) {
      const id: number = parseTrailingId(rawUrl, ORPHEUS_ARTIST_PREFIX.length);
      return { handled: id > 0, action: 'artist', targetId: id };
    }
    if (lower.startsWith(ORPHEUS_PLAYLIST_PREFIX)) {
      const id: number = parseTrailingId(rawUrl, ORPHEUS_PLAYLIST_PREFIX.length);
      return { handled: id > 0, action: 'playlist', targetId: id };
    }

    return { handled: false, action: 'unsupported', targetId: 0 };
  }
}

function parseTrailingId(rawUrl: string, prefixLength: number): number {
  const tail: string = rawUrl.slice(prefixLength);
  const slashIdx: number = tail.indexOf('/');
  const trimmed: string = slashIdx >= 0 ? tail.slice(0, slashIdx) : tail;
  const value: number = Number.parseInt(trimmed, 10);
  if (Number.isNaN(value) || value <= 0) {
    return 0;
  }
  return value;
}