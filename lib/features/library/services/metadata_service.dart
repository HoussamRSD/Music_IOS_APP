import 'dart:io';
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
  /// Extract metadata from an audio file
  /// Falls back to filename parsing if metadata_god fails
  Future<MetadataResult> extractMetadata(String filePath) async {
    try {
      // For now, implement basic filename parsing as fallback
      // TODO: Integrate metadata_god when platform channels are available
      return await _extractFromFilename(filePath);
    } catch (e) {
      // Fallback to filename parsing
      return await _extractFromFilename(filePath);
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

  /// Extract and save album artwork
  Future<String?> extractArtwork(String filePath) async {
    try {
      // TODO: Implement artwork extraction with metadata_god
      // For now, return null (no artwork)
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
