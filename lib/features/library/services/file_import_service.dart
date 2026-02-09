import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../../core/data/models/song.dart';
import '../data/song_repository.dart';
import 'metadata_service.dart';

class FileImportService {
  final SongRepository _songRepository;
  final MetadataService _metadataService;

  FileImportService({
    required SongRepository songRepository,
    required MetadataService metadataService,
  }) : _songRepository = songRepository,
       _metadataService = metadataService;

  /// Import audio files via file picker
  Future<List<Song>> importFiles() async {
    try {
      // Open file picker for audio files
      // Using FileType.any for iOS compatibility with document picker
      // This allows access to the Files app including iCloud Drive and On My iPhone
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      final List<Song> importedSongs = [];

      for (final file in result.files) {
        if (file.path == null) {
          debugPrint('Skipping file with null path: ${file.name}');
          continue;
        }

        // Filter by extension since we use FileType.any
        final ext = path.extension(file.path!).toLowerCase();
        if (!['.mp3', '.m4a', '.aac', '.wav', '.flac', '.ogg'].contains(ext)) {
          debugPrint('Skipping unsupported file type: $ext');
          continue;
        }

        try {
          final song = await _processAudioFile(file.path!);
          final songId = await _songRepository.addSong(song);
          importedSongs.add(song.copyWith(id: songId));
        } catch (e) {
          debugPrint('Error processing file ${file.name}: $e');
          // Log error but continue with other files
        }
      }

      return importedSongs;
    } catch (e) {
      debugPrint('Error picking files: $e');
      // Rethrow to let UI handle it if needed, or return empty
      return [];
    }
  }

  /// Process a single audio file
  Future<Song> _processAudioFile(String sourcePath) async {
    // 1. Copy file to app's music directory
    final destPath = await _copyToMusicDirectory(sourcePath);

    // 2. Extract metadata (includes artwork extraction)
    final metadata = await _metadataService.extractMetadata(destPath);

    // 3. Create Song model using artworkPath from metadata
    return Song(
      title: metadata.title,
      album: metadata.album,
      artists: metadata.artists,
      duration: metadata.duration,
      trackNumber: metadata.trackNumber,
      year: metadata.year,
      genre: metadata.genre,
      filePath: destPath,
      artworkPath: metadata.artworkPath,
      addedAt: DateTime.now(),
      hasEmbeddedLyrics: metadata.hasLyrics,
    );
  }

  /// Copy file to app's music directory
  Future<String> _copyToMusicDirectory(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final musicDir = Directory(path.join(appDir.path, 'music'));

    if (!await musicDir.exists()) {
      await musicDir.create(recursive: true);
    }

    final fileName = path.basename(sourcePath);
    final destPath = path.join(musicDir.path, fileName);

    // Handle duplicate filenames
    var finalPath = destPath;
    var counter = 1;
    while (await File(finalPath).exists()) {
      final nameWithoutExt = path.basenameWithoutExtension(fileName);
      final ext = path.extension(fileName);
      finalPath = path.join(musicDir.path, '${nameWithoutExt}_$counter$ext');
      counter++;
    }

    await File(sourcePath).copy(finalPath);
    return finalPath;
  }

  /// Get the music directory path (useful for showing to users)
  Future<String> getMusicDirectoryPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'music');
  }

  /// Scan the music directory for new audio files that aren't in the database
  /// This allows users to copy-paste files directly into the app's folder
  Future<List<Song>> scanMusicDirectory() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory(path.join(appDir.path, 'music'));

      // Create directory if it doesn't exist
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
        return []; // No files to scan
      }

      // Get all existing file paths from database
      final existingSongs = await _songRepository.getAllSongs();
      final existingPaths = existingSongs.map((s) => s.filePath).toSet();

      final List<Song> importedSongs = [];
      final supportedExtensions = [
        '.mp3',
        '.m4a',
        '.aac',
        '.wav',
        '.flac',
        '.ogg',
      ];

      // List all files in music directory
      await for (final entity in musicDir.list(recursive: true)) {
        if (entity is! File) continue;

        final ext = path.extension(entity.path).toLowerCase();
        if (!supportedExtensions.contains(ext)) continue;

        // Skip if already in database
        if (existingPaths.contains(entity.path)) continue;

        try {
          // Extract metadata and create song
          final metadata = await _metadataService.extractMetadata(entity.path);
          final song = Song(
            title: metadata.title,
            album: metadata.album,
            artists: metadata.artists,
            duration: metadata.duration,
            trackNumber: metadata.trackNumber,
            year: metadata.year,
            genre: metadata.genre,
            filePath: entity.path,
            artworkPath: metadata.artworkPath,
            addedAt: DateTime.now(),
            hasEmbeddedLyrics: metadata.hasLyrics,
          );

          final songId = await _songRepository.addSong(song);
          importedSongs.add(song.copyWith(id: songId));
          debugPrint('Imported from scan: ${song.title}');
        } catch (e) {
          debugPrint('Error processing scanned file ${entity.path}: $e');
        }
      }

      return importedSongs;
    } catch (e) {
      debugPrint('Error scanning music directory: $e');
      return [];
    }
  }
}

// Riverpod Providers
final metadataServiceProvider = Provider<MetadataService>((ref) {
  return MetadataService();
});

final fileImportServiceProvider = Provider<FileImportService>((ref) {
  return FileImportService(
    songRepository: ref.watch(songRepositoryProvider),
    metadataService: ref.watch(metadataServiceProvider),
  );
});
