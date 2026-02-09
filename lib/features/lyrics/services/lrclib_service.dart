import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/data/models/lyrics.dart';

/// Service for fetching lyrics from LRCLIB (no API key required)
class LrclibService {
  static const String _baseUrl = 'https://lrclib.net/api';
  static const String _userAgent = 'DOPLIN/1.0 (https://github.com/doplin-app)';

  /// Search for lyrics using track info
  /// Returns lyrics if found, null otherwise
  Future<LrclibResult?> searchLyrics({
    required String trackName,
    required String artistName,
    String? albumName,
    int? durationSeconds,
  }) async {
    try {
      // First try the get endpoint with exact match
      if (durationSeconds != null) {
        final getResult = await _getLyrics(
          trackName: trackName,
          artistName: artistName,
          albumName: albumName ?? '',
          duration: durationSeconds,
        );
        if (getResult != null) return getResult;
      }

      // Fall back to search endpoint
      return await _searchLyrics(trackName, artistName);
    } catch (e) {
      debugPrint('LRCLIB search error: $e');
      return null;
    }
  }

  /// Get lyrics using exact track signature
  Future<LrclibResult?> _getLyrics({
    required String trackName,
    required String artistName,
    required String albumName,
    required int duration,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/get').replace(
        queryParameters: {
          'track_name': trackName,
          'artist_name': artistName,
          'album_name': albumName,
          'duration': duration.toString(),
        },
      );

      final response = await http.get(uri, headers: {'User-Agent': _userAgent});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseResult(data);
      }
    } catch (e) {
      debugPrint('LRCLIB get error: $e');
    }
    return null;
  }

  /// Search lyrics by keywords
  Future<LrclibResult?> _searchLyrics(
    String trackName,
    String artistName,
  ) async {
    try {
      final query = '$trackName $artistName';
      final uri = Uri.parse(
        '$_baseUrl/search',
      ).replace(queryParameters: {'q': query});

      final response = await http.get(uri, headers: {'User-Agent': _userAgent});

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        if (results.isEmpty) return null;

        // Take the first (best) result
        return _parseResult(results.first);
      }
    } catch (e) {
      debugPrint('LRCLIB search error: $e');
    }
    return null;
  }

  /// Search lyrics with just a query string (for manual search)
  Future<List<LrclibResult>> searchByQuery(String query) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/search',
      ).replace(queryParameters: {'q': query});

      final response = await http.get(uri, headers: {'User-Agent': _userAgent});

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        return results
            .map((data) => _parseResult(data))
            .whereType<LrclibResult>()
            .toList();
      }
    } catch (e) {
      debugPrint('LRCLIB query search error: $e');
    }
    return [];
  }

  LrclibResult? _parseResult(Map<String, dynamic> data) {
    try {
      final syncedLyrics = data['syncedLyrics'] as String?;
      final plainLyrics = data['plainLyrics'] as String?;

      if (syncedLyrics == null && plainLyrics == null) return null;

      return LrclibResult(
        trackName: data['trackName'] as String? ?? '',
        artistName: data['artistName'] as String? ?? '',
        albumName: data['albumName'] as String?,
        duration: data['duration'] as int?,
        syncedLyrics: syncedLyrics,
        plainLyrics: plainLyrics,
      );
    } catch (e) {
      return null;
    }
  }

  /// Convert LRCLIB result to Lyrics model
  Lyrics? resultToLyrics(LrclibResult result, int songId) {
    if (result.syncedLyrics != null) {
      return Lyrics(
        songId: songId,
        syncedLyrics: _parseLrc(result.syncedLyrics!),
        source: 'LRCLIB (Synced)',
        lastUpdated: DateTime.now(),
      );
    } else if (result.plainLyrics != null) {
      return Lyrics(
        songId: songId,
        plainLyrics: result.plainLyrics,
        source: 'LRCLIB (Plain)',
        lastUpdated: DateTime.now(),
      );
    }
    return null;
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

    lines.sort((a, b) => a.timeMs.compareTo(b.timeMs));
    return lines;
  }
}

/// Result from LRCLIB API
class LrclibResult {
  final String trackName;
  final String artistName;
  final String? albumName;
  final int? duration;
  final String? syncedLyrics;
  final String? plainLyrics;

  LrclibResult({
    required this.trackName,
    required this.artistName,
    this.albumName,
    this.duration,
    this.syncedLyrics,
    this.plainLyrics,
  });

  bool get hasSynced => syncedLyrics != null && syncedLyrics!.isNotEmpty;
  bool get hasPlain => plainLyrics != null && plainLyrics!.isNotEmpty;
}

final lrclibServiceProvider = Provider<LrclibService>((ref) {
  return LrclibService();
});
