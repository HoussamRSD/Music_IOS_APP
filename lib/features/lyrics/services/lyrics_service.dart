import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models/lyrics.dart';
import '../../../core/data/models/song.dart';
import '../data/lyrics_repository.dart';
import 'package:path/path.dart' as path;
import 'lyrics_writer_service.dart';
import 'lrclib_service.dart';

class LyricsService {
  final LyricsRepository _repository;
  final LyricsWriterService _writerService;
  final LrclibService _lrclibService;

  LyricsService(this._repository, this._writerService, this._lrclibService);

  Future<Lyrics?> getLyrics(Song song, {bool searchOnline = true}) async {
    if (song.id == null) return null;

    debugPrint(
      'LyricsService: Getting lyrics for ${song.title} (ID: ${song.id})',
    );

    // 1. Check database first
    final cached = await _repository.getLyrics(song.id!);
    if (cached != null) {
      debugPrint('LyricsService: Found cached lyrics for ${song.title}');
      return cached;
    }

    // 2. Try to find local LRC file
    debugPrint('LyricsService: Checking local LRC for ${song.filePath}');
    final localLrc = await _findLocalLrc(song.filePath);
    if (localLrc != null) {
      debugPrint('LyricsService: Found local LRC');
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
    debugPrint('LyricsService: Checking embedded lyrics');
    final embedded = await _extractEmbeddedLyrics(song.filePath, song.id!);
    if (embedded != null) {
      debugPrint('LyricsService: Found embedded lyrics');
      await _repository.saveLyrics(embedded);
      return embedded;
    } else {
      debugPrint('LyricsService: No embedded lyrics found');
    }

    // 4. Search online via LRCLIB (if enabled)
    if (searchOnline) {
      debugPrint('LyricsService: Searching online');
      final online = await _searchOnline(song);
      if (online != null) {
        await _repository.saveLyrics(online);
        return online;
      }
    }

    debugPrint('LyricsService: No lyrics found anywhere');
    return null;
  }

  /// Search for lyrics online using LRCLIB
  Future<Lyrics?> _searchOnline(Song song) async {
    if (song.id == null) return null;

    try {
      debugPrint(
        'Searching LRCLIB for: ${song.title} - ${song.artists.join(", ")}',
      );

      // Calculate duration in seconds if available
      final durationSeconds = song.duration != null
          ? (song.duration! / 1000).round()
          : null;

      final result = await _lrclibService.searchLyrics(
        trackName: song.title,
        artistName: song.artists.isNotEmpty ? song.artists.first : '',
        albumName: song.album,
        durationSeconds: durationSeconds,
      );

      if (result != null) {
        debugPrint(
          'Found lyrics from LRCLIB: ${result.hasSynced ? "synced" : "plain"}',
        );
        return _lrclibService.resultToLyrics(result, song.id!);
      }
    } catch (e) {
      debugPrint('Online lyrics search error: $e');
    }
    return null;
  }

  /// Manual search for lyrics by query (for user-initiated search)
  Future<List<LrclibResult>> manualSearch(String query) async {
    return await _lrclibService.searchByQuery(query);
  }

  /// Apply a selected LRCLIB result to a song
  Future<Lyrics?> applyLrclibResult(LrclibResult result, int songId) async {
    final lyrics = _lrclibService.resultToLyrics(result, songId);
    if (lyrics != null) {
      await _repository.saveLyrics(lyrics);
    }
    return lyrics;
  }

  /// Manually save lyrics to database (e.g. after editing)
  Future<void> saveLyrics(Lyrics lyrics) async {
    await _repository.saveLyrics(lyrics);
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

  Future<Lyrics?> _extractEmbeddedLyrics(String filePath, int songId) async {
    try {
      final embeddedText = await _writerService.readEmbeddedLyrics(filePath);
      if (embeddedText == null || embeddedText.isEmpty) return null;

      // Check if embedded lyrics are synced (LRC format)
      if (_isLrcFormat(embeddedText)) {
        return Lyrics(
          songId: songId,
          syncedLyrics: _parseLrc(embeddedText),
          source: 'Embedded (Synced)',
          lastUpdated: DateTime.now(),
        );
      } else {
        return Lyrics(
          songId: songId,
          plainLyrics: embeddedText,
          source: 'Embedded (Plain)',
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      return null;
    }
  }

  /// Check if text is in LRC format
  bool _isLrcFormat(String text) {
    final RegExp lrcRegex = RegExp(r'\[\d{2}:\d{2}\.\d{2,3}\]');
    return lrcRegex.hasMatch(text);
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

  Future<void> invalidateCache(int songId) async {
    await _repository.deleteLyrics(songId);
  }
}

final lyricsWriterServiceProvider = Provider<LyricsWriterService>((ref) {
  return LyricsWriterService();
});

final lyricsServiceProvider = Provider<LyricsService>((ref) {
  return LyricsService(
    ref.watch(lyricsRepositoryProvider),
    ref.watch(lyricsWriterServiceProvider),
    ref.watch(lrclibServiceProvider),
  );
});
