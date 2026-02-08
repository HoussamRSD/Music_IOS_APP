import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:metadata_god/metadata_god.dart';

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
  /// Extract metadata from an audio file
  /// Falls back to filename parsing if tag extraction fails
  Future<MetadataResult> extractMetadata(String filePath) async {
    try {
      // Initialize MetadataGod if needed (usually safe to call repeatedly or check docs, but for safety we just call getMetadata)
      // MetadataGod.initialize(); // Not always needed depending on version, but good practice if available.
      // Actually v1.1.0 doesn't strictly require explicit init for single usage usually, but let's check.
      // We will just call getMetadata.

      final metadata = await MetadataGod.getMetadata(filePath);

      if (metadata != null) {
        // Extract artwork if available
        String? artworkPath;
        if (metadata.picture != null) {
          artworkPath = await _saveArtworkToDisk(
            metadata.picture!.data,
            filePath,
          );
        }

        return MetadataResult(
          title: metadata.title ?? path.basenameWithoutExtension(filePath),
          album: metadata.album,
          artists: metadata.artist != null ? [metadata.artist!] : [],
          duration: metadata.durationMs,
          trackNumber: metadata.trackNumber,
          year: metadata.year,
          genre: metadata.genre,
          artworkPath: artworkPath,
          hasLyrics: false,
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
    try {
      final metadata = await MetadataGod.getMetadata(filePath);
      if (metadata?.picture != null) {
        return await _saveArtworkToDisk(metadata!.picture!.data, filePath);
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
