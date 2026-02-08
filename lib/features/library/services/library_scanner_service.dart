import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../../core/data/models/song.dart';
import '../data/song_repository.dart';
import 'metadata_service.dart';

class LibraryScannerService {
  final SongRepository _songRepository;
  final MetadataService _metadataService;

  bool _isScanning = false;

  LibraryScannerService({
    required SongRepository songRepository,
    required MetadataService metadataService,
  }) : _songRepository = songRepository,
       _metadataService = metadataService;

  Future<void> scanLibrary() async {
    if (_isScanning) {
      debugPrint('Scan already in progress.');
      return;
    }
    _isScanning = true;
    debugPrint('Starting library scan...');

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory(path.join(appDir.path, 'music'));

      // Ensure music directory exists
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }

      // List all audio files in Documents/music recursively
      final List<FileSystemEntity> files = await _listFilesSafe(musicDir);

      // Also scan root Documents folder for user convenience
      final List<FileSystemEntity> rootFiles = await _listFilesSafe(
        appDir,
        recursive: false,
      );
      files.addAll(rootFiles);

      // Filter for audio extensions
      final audioFiles = files
          .where((file) {
            if (file is! File) return false;
            final ext = path.extension(file.path).toLowerCase();
            return [
              '.mp3',
              '.m4a',
              '.aac',
              '.flac',
              '.wav',
              '.ogg',
            ].contains(ext);
          })
          .cast<File>()
          .toList();

      debugPrint('Found ${audioFiles.length} potential audio files.');

      // Get existing songs from DB to avoid duplicates
      final existingSongs = await _songRepository.getAllSongs();
      final existingPaths = existingSongs.map((s) => s.filePath).toSet();

      final foundPaths = <String>{};
      int addedCount = 0;
      int removedCount = 0;

      for (final file in audioFiles) {
        foundPaths.add(file.path);

        if (!existingPaths.contains(file.path)) {
          // New file detected
          debugPrint('Adding new file: ${path.basename(file.path)}');
          await _processAndAddSong(file);
          addedCount++;
        }
      }

      // Cleanup: Remove songs from DB that no longer exist on disk
      for (final song in existingSongs) {
        // If song is NOT in the found list AND file is missing
        if (!foundPaths.contains(song.filePath)) {
          final file = File(song.filePath);
          // Double check existence to be safe
          if (!await file.exists()) {
            debugPrint(
              'Removing missing song: ${song.title} (${song.filePath})',
            );
            await _songRepository.deleteSong(song.id!);
            removedCount++;
          }
        }
      }

      debugPrint('Scan complete. Added: $addedCount, Removed: $removedCount');
    } catch (e) {
      debugPrint('Library scan failed: $e');
    } finally {
      _isScanning = false;
    }
  }

  Future<List<FileSystemEntity>> _listFilesSafe(
    Directory dir, {
    bool recursive = true,
  }) async {
    try {
      return await dir.list(recursive: recursive).toList();
    } catch (e) {
      debugPrint('Error listing directory ${dir.path}: $e');
      return [];
    }
  }

  Future<void> _processAndAddSong(File file) async {
    try {
      final metadata = await _metadataService.extractMetadata(file.path);
      final artworkPath = await _metadataService.extractArtwork(file.path);

      final song = Song(
        title: metadata.title,
        album: metadata.album,
        artists: metadata.artists,
        duration: metadata.duration,
        trackNumber: metadata.trackNumber,
        year: metadata.year,
        genre: metadata.genre,
        filePath: file.path,
        artworkPath: artworkPath,
        addedAt: DateTime.now(),
        hasEmbeddedLyrics: metadata.hasLyrics,
      );

      await _songRepository.addSong(song);
    } catch (e) {
      debugPrint('Failed to add song ${file.path}: $e');
    }
  }
}
