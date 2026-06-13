import media from '@ohos.multimedia.media';
import avSessionManager from '@ohos.multimedia.avsession';
import common from '@ohos.app.ability.common';
import { SongApi } from '../data/api/SongApi';
import { LikeApi } from '../data/api/LikeApi';
import { SongRepositoryImpl } from '../data/repository/SongRepositoryImpl';
import { LyricResponse, LyricSection } from '../domain/model/SongModels';
import { Song } from '../domain/model/Song';
import { GetSongDetailUseCase, SongDetailAggregate } from '../domain/usecase/GetSongDetailUseCase';
import { GetSongPlayUrlUseCase } from '../domain/usecase/GetSongPlayUrlUseCase';

export enum PlaybackMode {
  SEQUENTIAL = 0,
  REPEAT_ONE = 1,
  SHUFFLE = 2
}

export class PlayerEngine {
  private static instance: PlayerEngine | null = null;

  private repository: SongRepositoryImpl = new SongRepositoryImpl(new SongApi());
  private getSongPlayUrlUseCase: GetSongPlayUrlUseCase = new GetSongPlayUrlUseCase(this.repository);
  private getSongDetailUseCase: GetSongDetailUseCase = new GetSongDetailUseCase(this.repository);

  private avPlayer: media.AVPlayer | null = null;
  private playerState: string = '';
  private currentSongId: number = 0;
  private currentUrl: string = '';
  private progressTimerId: number = -1;
  private session: avSessionManager.AVSession | null = null;
  private sessionInited: boolean = false;
  private lastReportedDuration: number = 0;
  private currentTitle: string = '未选择歌曲';
  private currentArtist: string = '';
  private currentCover: string = '';
  private metaRequestVersion: number = 0;
  private lyricRequestVersion: number = 0;
  private playQueue: Song[] = [];
  private currentQueueIndex: number = -1;
  private playbackMode: PlaybackMode = PlaybackMode.SEQUENTIAL;
  private shuffleOrder: number[] = [];
  private shuffleCursor: number = -1;

  private constructor() {
    AppStorage.setOrCreate<boolean>('miniPlayerPlaying', false);
    AppStorage.setOrCreate<number>('selectedSongId', 0);
    AppStorage.setOrCreate<string>('miniPlayerTitle', '未选择歌曲');
    AppStorage.setOrCreate<string>('miniPlayerArtist', '');
    AppStorage.setOrCreate<string>('miniPlayerCover', '');
    AppStorage.setOrCreate<boolean>('miniPlayerVisible', false);
    AppStorage.setOrCreate<number>('playerCurrentMs', 0);
    AppStorage.setOrCreate<number>('playerDurationMs', 0);
    AppStorage.setOrCreate<string>('currentSongRawLyric', '');
    AppStorage.setOrCreate<string>('currentSongLyric', '');
    AppStorage.setOrCreate<string>('currentSongLyricError', '');
    AppStorage.setOrCreate<boolean>('currentSongLyricLoading', false);
    AppStorage.setOrCreate<string>('currentSongTranslationLyric', '');
    AppStorage.setOrCreate<string>('currentSongRomajiLyric', '');
    AppStorage.setOrCreate<boolean>('currentSongHasTranslation', false);
    AppStorage.setOrCreate<boolean>('currentSongHasRomaji', false);
    AppStorage.setOrCreate<Song[]>('playQueue', []);
    AppStorage.setOrCreate<number>('currentQueueIndex', -1);
    AppStorage.setOrCreate<number>('playbackMode', PlaybackMode.SEQUENTIAL);
    AppStorage.setOrCreate<boolean>('currentSongLiked', false);
  }

  static getInstance(): PlayerEngine {
    if (!PlayerEngine.instance) {
      PlayerEngine.instance = new PlayerEngine();
    }
    return PlayerEngine.instance;
  }

  async initSession(context: common.UIAbilityContext): Promise<void> {
    if (this.sessionInited) {
      return;
    }
    this.repository.setLikeApi(new LikeApi(context));
    this.session = await avSessionManager.createAVSession(context, 'netease_music_session', 'audio');

    this.session.on('play', async () => {
      await this.resume();
    });
    this.session.on('pause', async () => {
      await this.pause();
    });
    this.session.on('playNext', async () => {
      await this.next();
    });
    this.session.on('playPrevious', async () => {
      await this.prev();
    });
    this.session.on('seek', async (position: number) => {
      await this.seekTo(position);
    });
    this.session.on('toggleFavorite', async () => {
      await this.toggleFavorite();
    });
    this.session.on('setLoopMode', (mode: avSessionManager.LoopMode) => {
      this.applyLoopMode(mode);
    });

    await this.session.activate();
    this.sessionInited = true;
    await this.reportSessionMetadata();
    await this.reportSessionState();
    this.refreshCurrentSongLiked();
  }

  private refreshCurrentSongLiked(): void {
    const liked = this.currentSongId > 0 && SongRepositoryImpl.isLikedSong(this.currentSongId);
    AppStorage.setOrCreate<boolean>('currentSongLiked', liked);
  }

  async toggleFavorite(): Promise<void> {
    const songId = this.currentSongId;
    if (songId <= 0) {
      return;
    }
    const liked = SongRepositoryImpl.isLikedSong(songId);
    try {
      await this.repository.toggleSongLike(songId, !liked);
      if (liked) {
        SongRepositoryImpl.removeLikedSongId(songId);
      } else {
        SongRepositoryImpl.addLikedSongId(songId);
      }
      AppStorage.setOrCreate<boolean>('currentSongLiked', !liked);
      await this.reportSessionState();
    } catch (error) {
      console.error(`toggle favorite failed: ${(error as Error).message}`);
    }
  }

  private setPlaying(playing: boolean): void {
    AppStorage.setOrCreate<boolean>('miniPlayerPlaying', playing);
  }

  private setSongMeta(title: string, artist: string, cover: string): void {
    AppStorage.setOrCreate<string>('miniPlayerTitle', title);
    AppStorage.setOrCreate<string>('miniPlayerArtist', artist);
    AppStorage.setOrCreate<string>('miniPlayerCover', cover);
    AppStorage.setOrCreate<boolean>('miniPlayerVisible', true);
  }

  private setProgress(currentMs: number, durationMs: number): void {
    AppStorage.setOrCreate<number>('playerCurrentMs', currentMs);
    AppStorage.setOrCreate<number>('playerDurationMs', durationMs);
  }

  private setLyricState(rawLyric: string, lyric: string, errorText: string, loading: boolean): void {
    AppStorage.setOrCreate<string>('currentSongRawLyric', rawLyric);
    AppStorage.setOrCreate<string>('currentSongLyric', lyric);
    AppStorage.setOrCreate<string>('currentSongLyricError', errorText);
    AppStorage.setOrCreate<boolean>('currentSongLyricLoading', loading);
    AppStorage.setOrCreate<string>('currentSongTranslationLyric', '');
    AppStorage.setOrCreate<string>('currentSongRomajiLyric', '');
    AppStorage.setOrCreate<boolean>('currentSongHasTranslation', false);
    AppStorage.setOrCreate<boolean>('currentSongHasRomaji', false);
  }

  private setLyricExtras(translationLyric: string, romajiLyric: string,
    hasTranslation: boolean, hasRomaji: boolean): void {
    AppStorage.setOrCreate<string>('currentSongTranslationLyric', translationLyric);
    AppStorage.setOrCreate<string>('currentSongRomajiLyric', romajiLyric);
    AppStorage.setOrCreate<boolean>('currentSongHasTranslation', hasTranslation);
    AppStorage.setOrCreate<boolean>('currentSongHasRomaji', hasRomaji);
  }

  private setQueueState(songs: Song[], index: number): void {
    AppStorage.setOrCreate<Song[]>('playQueue', songs);
    AppStorage.setOrCreate<number>('currentQueueIndex', index);
  }

  private mapPlaybackState(): avSessionManager.PlaybackState {
    if (this.playerState === 'playing') {
      return avSessionManager.PlaybackState.PLAYBACK_STATE_PLAY;
    }
    if (this.playerState === 'paused') {
      return avSessionManager.PlaybackState.PLAYBACK_STATE_PAUSE;
    }
    return avSessionManager.PlaybackState.PLAYBACK_STATE_STOP;
  }

  private async reportSessionMetadata(): Promise<void> {
    if (!this.session) {
      return;
    }
    const duration = AppStorage.get<number>('playerDurationMs') ?? 0;
    await this.session.setAVMetadata({
      assetId: `${this.currentSongId}`,
      title: this.currentTitle,
      artist: this.currentArtist,
      duration: duration,
      mediaImage: this.currentCover
    });
  }

  private async reportSessionState(): Promise<void> {
    if (!this.session) {
      return;
    }
    const position = AppStorage.get<number>('playerCurrentMs') ?? 0;
    const duration = AppStorage.get<number>('playerDurationMs') ?? 0;
    if (duration > 0 && duration !== this.lastReportedDuration) {
      this.lastReportedDuration = duration;
      await this.reportSessionMetadata();
    }
    await this.session.setAVPlaybackState({
      state: this.mapPlaybackState(),
      position: {
        elapsedTime: position,
        updateTime: Date.now()
      },
      speed: 1,
      isFavorite: this.currentSongId > 0 && SongRepositoryImpl.isLikedSong(this.currentSongId),
      loopMode: this.mapLoopMode()
    });
  }

  private mapLoopMode(): avSessionManager.LoopMode {
    switch (this.playbackMode) {
      case PlaybackMode.REPEAT_ONE:
        return avSessionManager.LoopMode.LOOP_MODE_SINGLE;
      case PlaybackMode.SHUFFLE:
        return avSessionManager.LoopMode.LOOP_MODE_SHUFFLE;
      default:
        return avSessionManager.LoopMode.LOOP_MODE_SEQUENCE;
    }
  }

  private applyLoopMode(mode: avSessionManager.LoopMode): void {
    let target: PlaybackMode;
    switch (mode) {
      case avSessionManager.LoopMode.LOOP_MODE_SINGLE:
        target = PlaybackMode.REPEAT_ONE;
        break;
      case avSessionManager.LoopMode.LOOP_MODE_SHUFFLE:
        target = PlaybackMode.SHUFFLE;
        break;
      default:
        target = PlaybackMode.SEQUENTIAL;
        break;
    }
    this.setPlaybackMode(target);
  }

  private startProgressTimer(): void {
    this.stopProgressTimer();
    this.progressTimerId = setInterval(() => {
      if (!this.avPlayer) {
        return;
      }
      const duration = this.avPlayer.duration > 0 ? this.avPlayer.duration : 0;
      const current = this.avPlayer.currentTime > 0 ? this.avPlayer.currentTime : 0;
      this.setProgress(current, duration);
      this.reportSessionState().catch((error: Error) => {
        console.error(`report session state failed: ${error.message}`);
      });
    }, 500) as number;
  }

  private stopProgressTimer(): void {
    if (this.progressTimerId >= 0) {
      clearInterval(this.progressTimerId);
      this.progressTimerId = -1;
    }
  }

  private async ensurePlayer(): Promise<media.AVPlayer> {
    if (this.avPlayer) {
      return this.avPlayer;
    }
    this.avPlayer = await media.createAVPlayer();
    this.avPlayer.on('stateChange', (state: string) => {
      this.playerState = state;
      if (state === 'playing') {
        this.setPlaying(true);
        this.startProgressTimer();
      } else if (state === 'paused' || state === 'completed' || state === 'stopped' || state === 'released') {
        this.setPlaying(false);
        if (state === 'completed') {
          const duration = this.avPlayer ? this.avPlayer.duration : 0;
          this.setProgress(duration, duration);
          this.handleTrackCompleted().catch((error: Error) => {
            console.error(`auto advance failed: ${error.message}`);
          });
        }
        this.stopProgressTimer();
      }
      this.reportSessionState().catch((error: Error) => {
        console.error(`report session state failed: ${error.message}`);
      });
    });
    return this.avPlayer;
  }

  private async recreatePlayer(): Promise<media.AVPlayer> {
    if (this.avPlayer) {
      try {
        await this.avPlayer.release();
      } catch (error) {
        console.error(`release player failed: ${(error as Error).message}`);
      } finally {
        this.avPlayer = null;
        this.playerState = '';
      }
    }
    this.currentUrl = '';
    this.setProgress(0, 0);
    this.stopProgressTimer();
    return this.ensurePlayer();
  }

  private async waitForInitialized(timeoutMs: number = 3000): Promise<void> {
    const start = Date.now();
    while (Date.now() - start < timeoutMs) {
      if (this.playerState === 'initialized') {
        return;
      }
      await new Promise<void>((resolve) => {
        setTimeout(() => {
          resolve();
        }, 50);
      });
    }
    throw new Error(`播放器初始化超时，当前状态: ${this.playerState}`);
  }

  private async loadSongMeta(songId: number): Promise<void> {
    const requestVersion = ++this.metaRequestVersion;
    try {
      const aggregate: SongDetailAggregate = await this.getSongDetailUseCase.execute(songId);
      if (requestVersion !== this.metaRequestVersion || (AppStorage.get<number>('selectedSongId') ?? 0) !== songId) {
        return;
      }
      const title = aggregate.detail.name;
      const artist = aggregate.detail.ar.map((item) => item.name).join(' / ');
      this.currentTitle = title;
      this.currentArtist = artist;
      this.currentCover = aggregate.detail.al.picUrl;
      this.setSongMeta(title, artist, this.currentCover);
    } catch (error) {
      if (requestVersion !== this.metaRequestVersion || (AppStorage.get<number>('selectedSongId') ?? 0) !== songId) {
        return;
      }
      this.currentTitle = `歌曲 ${songId}`;
      this.currentArtist = '详情加载失败';
      this.currentCover = '';
      this.setSongMeta(`歌曲 ${songId}`, '详情加载失败', '');
    }
    this.refreshCurrentSongLiked();
    await this.reportSessionMetadata();
  }

  private resolveRawLyric(response: LyricResponse): string {
    if (response.lrc !== undefined && response.lrc.lyric.length > 0) {
      return response.lrc.lyric;
    }
    if (response.yrc !== undefined && response.yrc.lyric.length > 0) {
      return response.yrc.lyric;
    }
    if (response.tlyric !== undefined && response.tlyric.lyric.length > 0) {
      return response.tlyric.lyric;
    }
    return '';
  }

  private resolveSectionLyric(section: LyricSection | undefined): string {
    if (section === undefined) {
      return '';
    }
    return section.lyric;
  }

  private normalizeLyric(rawLyric: string): string {
    const lines = rawLyric.split('\n');
    const normalized: string[] = [];
    lines.forEach((line: string) => {
      const trimmed = line.trim();
      if (trimmed.length === 0 || trimmed.startsWith('{')) {
        return;
      }
      const text = trimmed
        .replace(/\[[^\]]*\]/g, '')
        .replace(/\([^)]*\)/g, '')
        .trim();
      if (text.length > 0) {
        normalized.push(text);
      }
    });
    return normalized.join('\n');
  }

  private async loadSongLyric(songId: number): Promise<void> {
    const requestVersion = ++this.lyricRequestVersion;
    this.setLyricState('', '', '', true);
    try {
      const response: LyricResponse = await this.repository.getSongLyric(songId);
      if (requestVersion !== this.lyricRequestVersion || (AppStorage.get<number>('selectedSongId') ?? 0) !== songId) {
        return;
      }
      const rawLyric = this.resolveRawLyric(response);
      const lyricText = this.normalizeLyric(rawLyric);
      this.setLyricState(rawLyric, lyricText.length > 0 ? lyricText : '暂无歌词', '', false);
      const translationRaw = this.resolveSectionLyric(response.tlyric);
      const romajiRaw = this.resolveSectionLyric(response.romalrc);
      const hasTranslation = translationRaw.trim().length > 0;
      const hasRomaji = romajiRaw.trim().length > 0;
      this.setLyricExtras(translationRaw, romajiRaw, hasTranslation, hasRomaji);
    } catch (error) {
      if (requestVersion !== this.lyricRequestVersion || (AppStorage.get<number>('selectedSongId') ?? 0) !== songId) {
        return;
      }
      const message = (error as Error).message;
      this.setLyricState('', '', message.length > 0 ? message : '歌词加载失败', false);
    }
  }

  async playSong(songId: number): Promise<void> {
    if (this.playQueue.length > 0) {
      const foundIndex = this.playQueue.findIndex((item: Song) => item.id === songId);
      if (foundIndex >= 0 && foundIndex !== this.currentQueueIndex) {
        if (this.playbackMode === PlaybackMode.SHUFFLE) {
          this.setShuffleOrder(foundIndex);
        }
        this.currentQueueIndex = foundIndex;
        AppStorage.setOrCreate<number>('currentQueueIndex', this.currentQueueIndex);
      }
    }
    const sameSongSelected = this.currentSongId === songId && this.currentUrl.length > 0;
    const canResumeExisting =
      sameSongSelected &&
      this.avPlayer !== null &&
      (this.playerState === 'paused' || this.playerState === 'completed');
    if (canResumeExisting) {
      AppStorage.setOrCreate<number>('selectedSongId', songId);
      await this.resume();
      return;
    }

    AppStorage.setOrCreate<number>('selectedSongId', songId);
    this.currentSongId = songId;
    this.currentTitle = `歌曲 ${songId}`;
    this.currentArtist = '加载中...';
    this.currentCover = '';
    this.setSongMeta(this.currentTitle, this.currentArtist, this.currentCover);
    this.setProgress(0, 0);
    this.setLyricState('', '', '', true);
    await this.reportSessionMetadata();
    await this.reportSessionState();
    this.loadSongMeta(songId).catch((error: Error) => {
      console.error(`load song meta failed: ${error.message}`);
    });
    this.loadSongLyric(songId).catch((error: Error) => {
      console.error(`load song lyric failed: ${error.message}`);
    });

    const playUrl = await this.getSongPlayUrlUseCase.execute(songId);
    if ((AppStorage.get<number>('selectedSongId') ?? 0) !== songId) {
      return;
    }
    let player = await this.ensurePlayer();

    if (this.currentSongId !== songId || this.currentUrl !== playUrl) {
      player = await this.recreatePlayer();
      player.url = playUrl;
      this.currentUrl = playUrl;
      await this.waitForInitialized();
      await player.prepare();
    } else if (this.playerState === 'initialized') {
      await player.prepare();
    } else if (this.playerState === 'stopped') {
      player = await this.recreatePlayer();
      player.url = playUrl;
      await this.waitForInitialized();
      await player.prepare();
    }

    await player.play();
    this.setPlaying(true);
    this.startProgressTimer();
    await this.reportSessionState();
  }

  async setQueue(songs: Song[], startIndex: number): Promise<void> {
    if (songs.length === 0) {
      return;
    }
    const clampedIndex = Math.max(0, Math.min(startIndex, songs.length - 1));
    this.playQueue = songs.slice();
    this.currentQueueIndex = clampedIndex;
    this.setQueueState(this.playQueue, this.currentQueueIndex);
    if (this.playbackMode === PlaybackMode.SHUFFLE) {
      this.setShuffleOrder(clampedIndex);
    }
    await this.playSong(this.playQueue[clampedIndex].id);
  }

  getPlaybackMode(): PlaybackMode {
    return this.playbackMode;
  }

  cyclePlaybackMode(): PlaybackMode {
    const next: PlaybackMode = (this.playbackMode + 1) % 3;
    this.setPlaybackMode(next);
    return next;
  }

  private setPlaybackMode(mode: PlaybackMode): void {
    this.playbackMode = mode;
    AppStorage.setOrCreate<number>('playbackMode', mode);
    if (mode === PlaybackMode.SHUFFLE) {
      if (this.playQueue.length > 0 && this.currentQueueIndex >= 0) {
        this.setShuffleOrder(this.currentQueueIndex);
      }
    } else {
      this.shuffleCursor = -1;
    }
    this.reportSessionState().catch((error: Error) => {
      console.error(`report loopMode failed: ${error.message}`);
    });
  }

  private setShuffleOrder(anchorIndex: number): void {
    const total = this.playQueue.length;
    if (total === 0) {
      this.shuffleOrder = [];
      this.shuffleCursor = -1;
      return;
    }
    const safeAnchor = Math.max(0, Math.min(anchorIndex, total - 1));
    const order: number[] = [];
    for (let i = 0; i < total; i++) {
      if (i !== safeAnchor) {
        order.push(i);
      }
    }
    for (let i = order.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      const tmp = order[i];
      order[i] = order[j];
      order[j] = tmp;
    }
    this.shuffleOrder = [safeAnchor, ...order];
    this.shuffleCursor = 0;
  }

  private async advanceShuffle(step: number): Promise<boolean> {
    if (this.shuffleOrder.length === 0) {
      return false;
    }
    const nextCursor = this.shuffleCursor + step;
    if (nextCursor < 0 || nextCursor >= this.shuffleOrder.length) {
      return false;
    }
    this.shuffleCursor = nextCursor;
    const nextIndex = this.shuffleOrder[this.shuffleCursor];
    if (nextIndex < 0 || nextIndex >= this.playQueue.length) {
      return false;
    }
    this.currentQueueIndex = nextIndex;
    this.setQueueState(this.playQueue, this.currentQueueIndex);
    await this.playSong(this.playQueue[this.currentQueueIndex].id);
    return true;
  }

  private async handleTrackCompleted(): Promise<void> {
    if (this.playbackMode === PlaybackMode.REPEAT_ONE) {
      if (this.avPlayer) {
        await this.avPlayer.seek(0);
        await this.avPlayer.play();
        this.setPlaying(true);
        this.startProgressTimer();
        await this.reportSessionState();
      }
      return;
    }
    if (this.playbackMode === PlaybackMode.SHUFFLE) {
      await this.next();
      return;
    }
    if (this.currentQueueIndex >= 0 && this.currentQueueIndex < this.playQueue.length - 1) {
      await this.next();
    }
  }

  async next(): Promise<boolean> {
    if (this.currentQueueIndex < 0 || this.playQueue.length === 0) {
      return false;
    }
    if (this.playbackMode === PlaybackMode.SHUFFLE) {
      return this.advanceShuffle(1);
    }
    if (this.currentQueueIndex >= this.playQueue.length - 1) {
      return false;
    }
    this.currentQueueIndex += 1;
    this.setQueueState(this.playQueue, this.currentQueueIndex);
    await this.playSong(this.playQueue[this.currentQueueIndex].id);
    return true;
  }

  async prev(): Promise<boolean> {
    if (this.currentQueueIndex < 0 || this.playQueue.length === 0) {
      return false;
    }
    if (this.playbackMode === PlaybackMode.SHUFFLE) {
      return this.advanceShuffle(-1);
    }
    if (this.currentQueueIndex <= 0) {
      return false;
    }
    this.currentQueueIndex -= 1;
    this.setQueueState(this.playQueue, this.currentQueueIndex);
    await this.playSong(this.playQueue[this.currentQueueIndex].id);
    return true;
  }

  async pause(): Promise<void> {
    if (!this.avPlayer) {
      return;
    }
    if (this.playerState === 'paused' || this.playerState === 'completed') {
      this.setPlaying(false);
      return;
    }
    await this.avPlayer.pause();
    this.setPlaying(false);
    this.stopProgressTimer();
    await this.reportSessionState();
  }

  async resume(): Promise<void> {
    if (!this.avPlayer) {
      const songId = AppStorage.get<number>('selectedSongId');
      if (songId && songId > 0) {
        await this.playSong(songId);
      }
      return;
    }
    await this.avPlayer.play();
    this.setPlaying(true);
    this.startProgressTimer();
    await this.reportSessionState();
  }

  async seekTo(positionMs: number): Promise<void> {
    if (!this.avPlayer) {
      return;
    }
    const duration = this.avPlayer.duration > 0 ? this.avPlayer.duration : 0;
    const target = Math.max(0, Math.min(positionMs, duration));
    await this.avPlayer.seek(target);
    this.setProgress(target, duration);
    await this.reportSessionState();
  }

  async togglePlay(): Promise<void> {
    const isPlaying = AppStorage.get<boolean>('miniPlayerPlaying') === true;
    if (isPlaying) {
      await this.pause();
    } else {
      await this.resume();
    }
  }
}
