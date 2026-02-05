import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models/playlist.dart';
import '../../../core/data/models/song.dart';
import '../../library/data/database_helper.dart';

class PlaylistRepository {
  final DatabaseHelper _db;

  PlaylistRepository(this._db);

  Future<List<Playlist>> getAllPlaylists() async {
    return _db.getAllPlaylists();
  }

  Future<int> createPlaylist(String name) async {
    final now = DateTime.now();
    final playlist = Playlist(name: name, createdAt: now, modifiedAt: now);
    return _db.createPlaylist(playlist);
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    await _db.updatePlaylist(playlist.copyWith(modifiedAt: DateTime.now()));
  }

  Future<void> deletePlaylist(int id) async {
    await _db.deletePlaylist(id);
  }

  Future<List<Song>> getSongsForPlaylist(int playlistId) async {
    return _db.getSongsForPlaylist(playlistId);
  }

  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    final songs = await getSongsForPlaylist(playlistId);
    final orderIndex = songs.length; // Add to end

    final playlistSong = PlaylistSong(
      playlistId: playlistId,
      songId: songId,
      orderIndex: orderIndex,
      addedAt: DateTime.now(),
    );
    await _db.addSongToPlaylist(playlistSong);

    // Update modifiedAt
    // We would need to fetch the playlist first, or have a direct DB method to update timestamp
  }

  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    await _db.removeSongFromPlaylist(playlistId, songId);
  }
}

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepository(DatabaseHelper.instance);
});
