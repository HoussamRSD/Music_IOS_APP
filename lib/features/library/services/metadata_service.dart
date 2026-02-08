import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_audio_tagger/flutter_audio_tagger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class MetadataResult {
  final String title;
  final String? album;
  final List<String> artists;
  final int? duration;
  final int? trackNumber;
  final int? year;
  final String? genre;
  final String? artworkPath;
  final bool hasLyrics;

  MetadataResult({
    required this.title,
    this.album,
    this.artists = const [],
    this.duration,
    this.trackNumber,
    this.year,
    this.genre,
    this.artworkPath,
    this.hasLyrics = false,
  });
}

class MetadataService {
  final _tagger = FlutterAudioTagger();

  /// Extract metadata from an audio file
  /// Falls back to filename parsing if tag extraction fails
  Future<MetadataResult> extractMetadata(String filePath) async {
    try {
      final tags = await _tagger.readTags(path: filePath);

      if (tags != null) {
        // Extract artwork if available
        String? artworkPath;
        if (tags.artwork != null) {
          artworkPath = await _saveArtworkToDisk(tags.artwork!, filePath);
        }

        return MetadataResult(
          title: tags.title?.isNotEmpty == true
              ? tags.title!
              : path.basenameWithoutExtension(filePath),
          album: tags.album,
          artists: tags.artist != null ? [tags.artist!] : [],
          duration:
              null, // FlutterAudioTagger might not return duration reliably, audio_player does
          trackNumber: int.tryParse(tags.track ?? ''),
          year: int.tryParse(tags.year ?? ''),
          genre: tags.genre,
          artworkPath: artworkPath,
          hasLyrics: false, // Tagger doesn't support lyrics yet
        );
      }

      return await _extractFromFilename(filePath);
    } catch (e) {
      // Fallback to filename parsing
      return await _extractFromFilename(filePath);
    }
  }

  Future<String?> _saveArtworkToDisk(
    Uint8List artworkBytes,
    String sourcePath,
  ) async {
    try {
      final cacheDir = await getArtworkCacheDir();
      final fileName = '${path.basenameWithoutExtension(sourcePath)}_cover.jpg';
      final file = File(path.join(cacheDir.path, fileName));

      if (!await file.exists()) {
        await file.writeAsBytes(artworkBytes);
      }
      return file.path;
    } catch (e) {
      return null;
    }
  }

  Future<MetadataResult> _extractFromFilename(String filePath) async {
    final fileName = path.basenameWithoutExtension(filePath);

    // Try to parse "Artist - Title" format
    final parts = fileName.split(' - ');
    String title = fileName;
    List<String> artists = ['Unknown Artist'];

    if (parts.length >= 2) {
      artists = [parts[0].trim()];
      title = parts.sublist(1).join(' - ').trim();
    }

    return MetadataResult(
      title: title.isNotEmpty ? title : 'Unknown Title',
      artists: artists,
      album: null,
      duration: null,
      trackNumber: null,
      year: null,
      genre: null,
      artworkPath: null,
      hasLyrics: false,
    );
  }

  /// Extract and save album artwork (Separate method if usage requires it, typically we do it in batch)
  Future<String?> extractArtwork(String filePath) async {
    // Already handled in extractMetadata, but exposed if needed separately
    try {
      final tags = await _tagger.readTags(path: filePath);
      if (tags?.artwork != null) {
        return await _saveArtworkToDisk(tags!.artwork!, filePath);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get the app's artwork cache directory
  Future<Directory> getArtworkCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final artworkDir = Directory(path.join(appDir.path, 'artwork'));
    if (!await artworkDir.exists()) {
      await artworkDir.create(recursive: true);
    }
    return artworkDir;
  }
}
