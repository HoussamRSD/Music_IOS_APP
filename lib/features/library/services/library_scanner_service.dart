import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../../core/data/models/song.dart';
import '../data/song_repository.dart';
import 'metadata_service.dart';

class ScanResult {
  final int added;
  final int updated;
  final int removed;

  const ScanResult({this.added = 0, this.updated = 0, this.removed = 0});
}

class LibraryScannerService {
  final SongRepository _songRepository;
  final MetadataService _metadataService;

  bool _isScanning = false;

  LibraryScannerService({
    required SongRepository songRepository,
    required MetadataService metadataService,
  }) : _songRepository = songRepository,
       _metadataService = metadataService;

  Future<ScanResult> scanLibrary({bool forceRescan = false}) async {
    if (_isScanning) {
      debugPrint('Scan already in progress.');
      return const ScanResult();
    }
    _isScanning = true;
    debugPrint('Starting library scan (force: $forceRescan)...');

    int addedCount = 0;
    int updatedCount = 0;
    int removedCount = 0;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      // ... (directory setup same as before)
      final musicDir = Directory(path.join(appDir.path, 'music'));

      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }

      final List<FileSystemEntity> files = await _listFilesSafe(musicDir);
      final List<FileSystemEntity> rootFiles = await _listFilesSafe(
        appDir,
        recursive: false,
      );
      files.addAll(rootFiles);

      // Filter for audio files (same logic)
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

      final existingSongs = await _songRepository.getAllSongs();
      // Map filePath to Song for easier lookup
      final existingMap = {for (var s in existingSongs) s.filePath: s};

      final foundPaths = <String>{};
      // int addedCount = 0; // Moved declaration
      // int updatedCount = 0; // Moved declaration
      // int removedCount = 0; // Moved declaration

      for (final file in audioFiles) {
        foundPaths.add(file.path);

        final existingSong = existingMap[file.path];

        if (existingSong == null) {
          // New file
          debugPrint('Adding new file: ${path.basename(file.path)}');
          await _processAndAddSong(file);
          addedCount++;
        } else if (forceRescan) {
          // Existing file, force update
          debugPrint('Updating file: ${path.basename(file.path)}');
          await _processAndUpdateSong(file, existingSong);
          updatedCount++;
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

      debugPrint(
        'Scan complete. Added: $addedCount, Updated: $updatedCount, Removed: $removedCount',
      );
    } catch (e) {
      debugPrint('Library scan failed: $e');
    } finally {
      _isScanning = false;
    }

    return ScanResult(
      added: addedCount,
      updated: updatedCount,
      removed: removedCount,
    );
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
      // Artwork is already extracted and cached in extractMetadata()

      final song = Song(
        title: metadata.title,
        album: metadata.album,
        artists: metadata.artists,
        duration: metadata.duration,
        trackNumber: metadata.trackNumber,
        year: metadata.year,
        genre: metadata.genre,
        filePath: file.path,
        artworkPath: metadata.artworkPath,
        addedAt: DateTime.now(),
        hasEmbeddedLyrics: metadata.hasLyrics,
      );

      await _songRepository.addSong(song);
    } catch (e) {
      debugPrint('Failed to add song ${file.path}: $e');
    }
  }

  Future<void> _processAndUpdateSong(File file, Song existingSong) async {
    try {
      final metadata = await _metadataService.extractMetadata(file.path);
      // Artwork is already extracted and cached in extractMetadata()
      // Use new artwork if available, otherwise keep existing

      final updatedSong = existingSong.copyWith(
        title: metadata.title,
        album: metadata.album,
        artists: metadata.artists,
        duration: metadata.duration,
        trackNumber: metadata.trackNumber,
        year: metadata.year,
        genre: metadata.genre,
        artworkPath: metadata.artworkPath ?? existingSong.artworkPath,
        // Don't update addedAt, playCount, lyrics, etc.
        hasEmbeddedLyrics: metadata.hasLyrics,
      );

      await _songRepository.updateSong(updatedSong);
    } catch (e) {
      debugPrint('Failed to update song ${file.path}: $e');
    }
  }
}
