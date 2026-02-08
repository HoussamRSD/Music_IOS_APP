import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
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
      debugPrint('MetadataService: Reading metadata from: $filePath');

      final metadata = await MetadataGod.readMetadata(file: filePath);

      debugPrint(
        'MetadataService: Title=${metadata.title}, Artist=${metadata.artist}',
      );
      debugPrint(
        'MetadataService: Picture available: ${metadata.picture != null}',
      );
      if (metadata.picture != null) {
        debugPrint(
          'MetadataService: Picture size: ${metadata.picture!.data.length} bytes',
        );
      }

      // Extract artwork if available
      String? artworkPath;
      if (metadata.picture != null && metadata.picture!.data.isNotEmpty) {
        artworkPath = await _saveArtworkToDisk(
          metadata.picture!.data,
          filePath,
        );
        debugPrint('MetadataService: Artwork saved to: $artworkPath');
      }

      return MetadataResult(
        title: metadata.title ?? path.basenameWithoutExtension(filePath),
        album: metadata.album,
        artists: metadata.artist != null ? [metadata.artist!] : [],
        duration: metadata.durationMs?.toInt(),
        trackNumber: metadata.trackNumber,
        year: metadata.year,
        genre: metadata.genre,
        artworkPath: artworkPath,
        hasLyrics: false,
      );
    } catch (e, stackTrace) {
      // Fallback to filename parsing
      debugPrint('MetadataService: Error reading metadata: $e');
      debugPrint('MetadataService: Stack trace: $stackTrace');
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
      /*
      final metadata = await MetadataGod.getMetadata(filePath);
      if (metadata?.picture != null) {
        return await _saveArtworkToDisk(metadata!.picture!.data, filePath);
      }
      */
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get the app's artwork cache directory
  /*
  Future<String> _saveArtworkToDisk(List<int> bytes, String audioPath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final artworkDir = Directory('${appDir.path}/artwork_cache');
    
    if (!await artworkDir.exists()) {
      await artworkDir.create(recursive: true);
    }

    // Create a unique hash for the artwork based on path
    // Using simple hash might have collisions but acceptable for cache
    final hash = audioPath.hashCode;
    final artworkPath = '${artworkDir.path}/$hash.jpg';
    final file = File(artworkPath);

    if (!await file.exists()) {
      await file.writeAsBytes(bytes);
    }

    return artworkPath;
  }
  */
  Future<Directory> getArtworkCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final artworkDir = Directory(path.join(appDir.path, 'artwork'));
    if (!await artworkDir.exists()) {
      await artworkDir.create(recursive: true);
    }
    return artworkDir;
  }
}
