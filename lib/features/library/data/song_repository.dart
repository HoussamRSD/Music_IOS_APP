import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models/song.dart';
import 'database_helper.dart';

class SongRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Song>> getAllSongs() async {
    return await _dbHelper.getAllSongs();
  }

  Future<Song?> getSong(int id) async {
    return await _dbHelper.getSong(id);
  }

  Future<int> addSong(Song song) async {
    return await _dbHelper.insertSong(song);
  }

  Future<void> updateSong(Song song) async {
    await _dbHelper.updateSong(song);
  }

  Future<void> deleteSong(int id) async {
    await _dbHelper.deleteSong(id);
  }

  // Favorites methods

  Future<List<Song>> getFavoriteSongs() async {
    return await _dbHelper.getFavoriteSongs();
  }

  Future<void> toggleFavorite(int songId, bool isFavorite) async {
    await _dbHelper.toggleFavorite(songId, isFavorite);
  }
}

// Riverpod Provider
final songRepositoryProvider = Provider<SongRepository>((ref) {
  return SongRepository();
});
