import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models/lyrics.dart';
import '../../library/data/database_helper.dart';

class LyricsRepository {
  final DatabaseHelper _db;

  LyricsRepository(this._db);

  Future<Lyrics?> getLyrics(int songId) async {
    return _db.getLyricsBySongId(songId);
  }

  Future<void> saveLyrics(Lyrics lyrics) async {
    final existing = await _db.getLyricsBySongId(lyrics.songId);
    if (existing != null) {
      await _db.updateLyrics(lyrics.copyWith(id: existing.id));
    } else {
      await _db.insertLyrics(lyrics);
    }
  }
}

final lyricsRepositoryProvider = Provider<LyricsRepository>((ref) {
  return LyricsRepository(DatabaseHelper.instance);
});
