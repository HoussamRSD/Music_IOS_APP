import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models/playlist.dart';
import '../../../core/data/models/song.dart';
import '../data/playlist_repository.dart';

class PlaylistService {
  final PlaylistRepository _repository;

  PlaylistService(this._repository);

  Future<List<Playlist>> getPlaylists() => _repository.getAllPlaylists();

  Future<int?> createPlaylist(String name) async {
    if (name.trim().isEmpty) return null;
    return await _repository.createPlaylist(name.trim());
  }

  Future<void> deletePlaylist(int id) => _repository.deletePlaylist(id);

  Future<List<Song>> getSongs(int playlistId) =>
      _repository.getSongsForPlaylist(playlistId);

  Future<void> addSongsToPlaylist(int playlistId, List<Song> songs) async {
    for (final song in songs) {
      if (song.id != null) {
        await _repository.addSongToPlaylist(playlistId, song.id!);
      }
    }
  }

  Future<void> removeSong(int playlistId, Song song) async {
    if (song.id != null) {
      await _repository.removeSongFromPlaylist(playlistId, song.id!);
    }
  }

  // Reorder logic will go here later
}

final playlistServiceProvider = Provider<PlaylistService>((ref) {
  return PlaylistService(ref.watch(playlistRepositoryProvider));
});

final playlistsProvider = FutureProvider<List<Playlist>>((ref) async {
  final service = ref.watch(playlistServiceProvider);
  return service.getPlaylists();
});

final playlistSongsProvider = FutureProvider.family<List<Song>, int>((
  ref,
  playlistId,
) async {
  final service = ref.watch(playlistServiceProvider);
  return service.getSongs(playlistId);
});
