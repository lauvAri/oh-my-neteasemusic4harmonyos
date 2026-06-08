import { Song } from '../../music/domain/model/Song';
import { SongArtist, SongAlbum } from '../../music/domain/model/SongModels';
import { SearchSongItem } from './model/SearchModels';

export function mapSearchSongToSong(item: SearchSongItem): Song {
  const ar: SongArtist[] = (item.artists ?? []).map((artist): SongArtist => {
    const out: SongArtist = {
      id: artist.id,
      name: artist.name ?? ''
    };
    return out;
  });

  const al: SongAlbum = {
    id: item.album?.id ?? 0,
    name: item.album?.name ?? '',
    picUrl: item.album?.picUrl ?? ''
  };

  const song: Song = {
    id: item.id,
    name: item.name ?? '',
    ar: ar,
    al: al,
    dt: item.duration ?? 0
  };
  return song;
}
