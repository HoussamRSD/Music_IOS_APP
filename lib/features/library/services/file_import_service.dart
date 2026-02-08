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
