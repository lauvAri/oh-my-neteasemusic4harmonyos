import { describe, it, expect } from '@ohos/hypium';
import { OrpheusUrlRouter } from '../main/ets/common/util/OrpheusUrlRouter';

export default function orpheusUrlRouterTest() {
  describe('OrpheusUrlRouter.parse', () => {
    it('parses orpheus://song/{id}', 0, () => {
      const r = OrpheusUrlRouter.parse('orpheus://song/123');
      expect(r.handled).assertTrue();
      expect(r.action).assertEqual('song');
      expect(r.targetId).assertEqual(123);
    });

    it('parses orpheus://album/{id}', 0, () => {
      const r = OrpheusUrlRouter.parse('orpheus://album/377003944');
      expect(r.handled).assertTrue();
      expect(r.action).assertEqual('album');
      expect(r.targetId).assertEqual(377003944);
    });

    it('parses orpheus://artist/{id}', 0, () => {
      const r = OrpheusUrlRouter.parse('orpheus://artist/123');
      expect(r.handled).assertTrue();
      expect(r.action).assertEqual('artist');
      expect(r.targetId).assertEqual(123);
    });

    it('parses orpheus://playlist/{id}', 0, () => {
      const r = OrpheusUrlRouter.parse('orpheus://playlist/456');
      expect(r.handled).assertTrue();
      expect(r.action).assertEqual('playlist');
      expect(r.targetId).assertEqual(456);
    });

    it('rejects orpheus://song/0', 0, () => {
      const r = OrpheusUrlRouter.parse('orpheus://song/0');
      expect(r.handled).assertFalse();
      expect(r.action).assertEqual('song');
      expect(r.targetId).assertEqual(0);
    });

    it('rejects orpheus://song/abc', 0, () => {
      const r = OrpheusUrlRouter.parse('orpheus://song/abc');
      expect(r.handled).assertFalse();
      expect(r.action).assertEqual('song');
      expect(r.targetId).assertEqual(0);
    });

    it('tolerates orpheus://song/{id}?x=1', 0, () => {
      const r = OrpheusUrlRouter.parse('orpheus://song/123?x=1');
      expect(r.handled).assertTrue();
      expect(r.action).assertEqual('song');
      expect(r.targetId).assertEqual(123);
    });

    it('tolerates orpheus://song/{id}/extra', 0, () => {
      const r = OrpheusUrlRouter.parse('orpheus://song/123/extra');
      expect(r.handled).assertTrue();
      expect(r.action).assertEqual('song');
      expect(r.targetId).assertEqual(123);
    });

    it('is case-insensitive on scheme prefix', 0, () => {
      const r = OrpheusUrlRouter.parse('Orpheus://Song/123');
      expect(r.handled).assertTrue();
      expect(r.action).assertEqual('song');
      expect(r.targetId).assertEqual(123);
    });

    it('recognizes http url as web action', 0, () => {
      const r = OrpheusUrlRouter.parse('https://y.music.163.com/g/yida/act/xxx');
      expect(r.handled).assertTrue();
      expect(r.action).assertEqual('web');
      expect(r.httpUrl).assertEqual('https://y.music.163.com/g/yida/act/xxx');
    });

    it('recognizes http (non-https) url as web action', 0, () => {
      const r = OrpheusUrlRouter.parse('http://example.com/x');
      expect(r.handled).assertTrue();
      expect(r.action).assertEqual('web');
      expect(r.httpUrl).assertEqual('http://example.com/x');
    });

    it('rejects unknown orpheus action', 0, () => {
      const r = OrpheusUrlRouter.parse('orpheus://unknown/1');
      expect(r.handled).assertFalse();
      expect(r.action).assertEqual('unsupported');
    });

    it('rejects unknown scheme', 0, () => {
      const r = OrpheusUrlRouter.parse('weixin://profile/abc');
      expect(r.handled).assertFalse();
      expect(r.action).assertEqual('unsupported');
    });

    it('rejects empty string', 0, () => {
      const r = OrpheusUrlRouter.parse('');
      expect(r.handled).assertFalse();
      expect(r.action).assertEqual('unsupported');
    });

    it('recognizes https://music.163.com/m/download as download action', 0, () => {
      const url: string = 'https://music.163.com/m/download?from=test';
      const r = OrpheusUrlRouter.parse(url);
      expect(r.handled).assertTrue();
      expect(r.action).assertEqual('download');
      expect(r.httpUrl).assertEqual(url);
    });

    it('recognizes https://music.163.com/download as download action', 0, () => {
      const url: string = 'https://music.163.com/download';
      const r = OrpheusUrlRouter.parse(url);
      expect(r.handled).assertTrue();
      expect(r.action).assertEqual('download');
    });

    it('recognizes https://y.music.163.com/download as download action', 0, () => {
      const url: string = 'https://y.music.163.com/download';
      const r = OrpheusUrlRouter.parse(url);
      expect(r.handled).assertTrue();
      expect(r.action).assertEqual('download');
    });

    it('recognizes https://music.163.com/api/mobile/download as download action', 0, () => {
      const url: string = 'https://music.163.com/api/mobile/download?resourceType=song&resourceValue=1';
      const r = OrpheusUrlRouter.parse(url);
      expect(r.handled).assertTrue();
      expect(r.action).assertEqual('download');
    });

    it('recognizes https://interface.music.163.com/api/package/download/... as download action', 0, () => {
      const url: string = 'https://interface.music.163.com/api/package/download/deeplink?market=wb';
      const r = OrpheusUrlRouter.parse(url);
      expect(r.handled).assertTrue();
      expect(r.action).assertEqual('download');
    });

    it('ignores /download on non-netease host', 0, () => {
      const url: string = 'https://example.com/download';
      const r = OrpheusUrlRouter.parse(url);
      expect(r.handled).assertTrue();
      expect(r.action).assertEqual('web');
    });

    it('ignores /m/download-like path on non-netease host', 0, () => {
      const url: string = 'https://example.com/m/download';
      const r = OrpheusUrlRouter.parse(url);
      expect(r.handled).assertTrue();
      expect(r.action).assertEqual('web');
    });

    it('ignores /api/download on non-netease host', 0, () => {
      const url: string = 'https://example.com/api/mobile/download';
      const r = OrpheusUrlRouter.parse(url);
      expect(r.handled).assertTrue();
      expect(r.action).assertEqual('web');
    });

    it('does not match /downloads (plural) on netease host', 0, () => {
      const url: string = 'https://music.163.com/downloads';
      const r = OrpheusUrlRouter.parse(url);
      expect(r.handled).assertTrue();
      expect(r.action).assertEqual('web');
    });

    it('download match is case-insensitive on host', 0, () => {
      const url: string = 'HTTPS://MUSIC.163.COM/M/DOWNLOAD';
      const r = OrpheusUrlRouter.parse(url);
      expect(r.handled).assertTrue();
      expect(r.action).assertEqual('download');
    });

    it('preserves http url with download path as download action', 0, () => {
      const url: string = 'http://music.163.com/m/download';
      const r = OrpheusUrlRouter.parse(url);
      expect(r.handled).assertTrue();
      expect(r.action).assertEqual('download');
    });
  });
}
