import 'dart:io';
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
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, // audio type can be flaky on some platforms
        allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'flac'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      final List<Song> importedSongs = [];

      for (final file in result.files) {
        if (file.path == null) continue;

        try {
          final song = await _processAudioFile(file.path!);
          final songId = await _songRepository.addSong(song);
          importedSongs.add(song.copyWith(id: songId));
        } catch (e) {
          // Log error but continue with other files
        }
      }

      return importedSongs;
    } catch (e) {
      return [];
    }
  }

  /// Process a single audio file
  Future<Song> _processAudioFile(String sourcePath) async {
    // 1. Copy file to app's music directory
    final destPath = await _copyToMusicDirectory(sourcePath);

    // 2. Extract metadata
    final metadata = await _metadataService.extractMetadata(destPath);

    // 3. Extract artwork (if available)
    final artworkPath = await _metadataService.extractArtwork(destPath);

    // 4. Create Song model
    return Song(
      title: metadata.title,
      album: metadata.album,
      artists: metadata.artists,
      duration: metadata.duration,
      trackNumber: metadata.trackNumber,
      year: metadata.year,
      genre: metadata.genre,
      filePath: destPath,
      artworkPath: artworkPath,
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
