import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models/lyrics.dart';
import '../../../core/data/models/song.dart';
import '../data/lyrics_repository.dart';
import 'package:path/path.dart' as path;

class LyricsService {
  final LyricsRepository _repository;

  LyricsService(this._repository);

  Future<Lyrics?> getLyrics(Song song) async {
    if (song.id == null) return null;

    // 1. Check database first
    final cached = await _repository.getLyrics(song.id!);
    if (cached != null) return cached;

    // 2. Try to find local LRC file
    final localLrc = await _findLocalLrc(song.filePath);
    if (localLrc != null) {
      final lyrics = Lyrics(
        songId: song.id!,
        syncedLyrics: _parseLrc(localLrc),
        source: 'LRC File',
        lastUpdated: DateTime.now(),
      );
      await _repository.saveLyrics(lyrics);
      return lyrics;
    }

    // 3. Try embedded lyrics
    final embedded = await _extractEmbeddedLyrics(song.filePath);
    if (embedded != null) {
      final lyrics = Lyrics(
        songId: song.id!,
        plainLyrics: embedded,
        source: 'Embedded',
        lastUpdated: DateTime.now(),
      );
      await _repository.saveLyrics(lyrics);
      return lyrics;
    }

    // 4. Online search (Future)
    return null;
  }

  Future<String?> _findLocalLrc(String audioPath) async {
    try {
      final lrcPath = path.setExtension(audioPath, '.lrc');
      final file = File(lrcPath);
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      // Ignore errors
    }
    return null;
  }

  Future<String?> _extractEmbeddedLyrics(String path) async {
    try {
      // Note: MetadataGod API currently doesn't expose USLT lyrics frame directly.
      // We will implement this when the plugin supports it or switch to a different parser.
      return null;
    } catch (e) {
      return null;
    }
  }

  List<LyricLine> _parseLrc(String lrcContent) {
    final lines = <LyricLine>[];
    final RegExp regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (final line in lrcContent.split('\n')) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millisPart = match.group(3)!;

        // Calculate total milliseconds
        final ms =
            minutes * 60000 +
            seconds * 1000 +
            (millisPart.length == 2
                ? int.parse(millisPart) * 10
                : int.parse(millisPart));

        final text = match.group(4)?.trim() ?? '';
        if (text.isNotEmpty) {
          lines.add(LyricLine(timeMs: ms, text: text));
        }
      }
    }

    // Sort just in case
    lines.sort((a, b) => a.timeMs.compareTo(b.timeMs));
    return lines;
  }
}

final lyricsServiceProvider = Provider<LyricsService>((ref) {
  return LyricsService(ref.watch(lyricsRepositoryProvider));
});
