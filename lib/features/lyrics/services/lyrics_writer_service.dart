import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_audio_tagger/flutter_audio_tagger.dart';
import 'package:flutter_audio_tagger/tag.dart';

/// Service for writing lyrics to audio file metadata
class LyricsWriterService {
  final FlutterAudioTagger _tagger = FlutterAudioTagger();

  /// Write plain text lyrics to audio file USLT frame
  Future<bool> writePlainLyrics(String filePath, String lyrics) async {
    bool nativeSuccess = false;
    try {
      // Read existing metadata
      final tag = await _tagger.getAllTags(filePath);

      if (tag != null) {
        // Create updated tag with new lyrics
        final updatedTag = Tag(
          title: tag.title,
          artist: tag.artist,
          album: tag.album,
          year: tag.year,
          genre: tag.genre,
          artwork: tag.artwork,
          lyrics: lyrics,
        );

        // Write back to file
        await _tagger.editTags(updatedTag, filePath);
        nativeSuccess = true;
      }
    } catch (e) {
      developer.log(
        'Error writing plain lyrics natively: $e',
        name: 'LyricsWriterService',
      );
    }

    if (nativeSuccess) return true;

    // Fallback to Python script
    return await _writeLyricsWithPython(filePath, lyrics);
  }

  /// Write synced LRC lyrics to audio file
  /// Note: This writes LRC as plain text to USLT frame
  Future<bool> writeSyncedLyrics(String filePath, String lrcContent) async {
    bool nativeSuccess = false;
    try {
      // Read existing metadata
      final tag = await _tagger.getAllTags(filePath);
      if (tag != null) {
        // Create updated tag with LRC content as lyrics
        final updatedTag = Tag(
          title: tag.title,
          artist: tag.artist,
          album: tag.album,
          year: tag.year,
          genre: tag.genre,
          artwork: tag.artwork,
          lyrics: lrcContent,
        );

        // Write back to file
        await _tagger.editTags(updatedTag, filePath);
        nativeSuccess = true;
      }
    } catch (e) {
      developer.log(
        'Error writing synced lyrics natively: $e',
        name: 'LyricsWriterService',
      );
    }

    if (nativeSuccess) return true;

    // Fallback to Python script
    return await _writeLyricsWithPython(filePath, lrcContent);
  }

  Future<bool> _writeLyricsWithPython(String filePath, String lyrics) async {
    debugPrint(
      'LyricsWriterService: Trying Python script fallback for writing...',
    );
    try {
      final scriptPath = 'scripts/write_lyrics.py';
      if (await File(scriptPath).exists()) {
        final result = await Process.run('python', [
          scriptPath,
          filePath,
          lyrics,
        ], stdoutEncoding: utf8);

        if (result.exitCode == 0) {
          debugPrint(
            'LyricsWriterService: Python script wrote lyrics successfully!',
          );
          return true;
        } else {
          debugPrint(
            'LyricsWriterService: Python write failed (code ${result.exitCode})',
          );
          debugPrint('LyricsWriterService: Python stderr: ${result.stderr}');
        }
      } else {
        debugPrint(
          'LyricsWriterService: Python script not found at $scriptPath',
        );
      }
    } catch (e) {
      debugPrint('LyricsWriterService: Python write error: $e');
    }
    return false;
  }

  /// Read embedded lyrics from audio file
  Future<String?> readEmbeddedLyrics(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('LyricsWriterService: File not found at $filePath');
        return null;
      }

      debugPrint('LyricsWriterService: Reading embedded lyrics from $filePath');

      // 1. Try FlutterAudioTagger
      String? lyrics;
      try {
        final tag = await _tagger.getAllTags(filePath);
        lyrics = tag?.lyrics;
      } catch (e) {
        debugPrint('LyricsWriterService: FlutterAudioTagger failed: $e');
      }

      // 2. Fallback to Python script (mutagen) if null or empty
      if (lyrics == null || lyrics.isEmpty) {
        debugPrint('LyricsWriterService: Trying Python script fallback...');
        try {
          final scriptPath = 'scripts/read_lyrics.py';
          // Check if script exists
          if (await File(scriptPath).exists()) {
            final result = await Process.run('python', [
              scriptPath,
              filePath,
            ], stdoutEncoding: utf8);

            if (result.exitCode == 0) {
              final output = result.stdout.toString().trim();
              if (output.isNotEmpty) {
                lyrics = output;
                debugPrint('LyricsWriterService: Python script found lyrics!');
              }
            } else {
              debugPrint(
                'LyricsWriterService: Python script failed (code ${result.exitCode})',
              );
              debugPrint(
                'LyricsWriterService: Python stderr: ${result.stderr}',
              );
            }
          } else {
            debugPrint(
              'LyricsWriterService: Python script not found at $scriptPath',
            );
          }
        } catch (e) {
          debugPrint('LyricsWriterService: Python fallback error: $e');
        }
      }

      debugPrint(
        'LyricsWriterService: Read result: ${lyrics?.isNotEmpty == true ? "Found (${lyrics!.length} chars)" : "Null/Empty"}',
      );
      return lyrics;
    } catch (e) {
      developer.log(
        'Error reading embedded lyrics: $e',
        name: 'LyricsWriterService',
      );
      debugPrint('LyricsWriterService: Error: $e');
      return null;
    }
  }

  /// Check if file is writable
  /// Returns true if native tagger works OR if Python script is available
  Future<bool> canWriteToFile(String filePath) async {
    try {
      final tag = await _tagger.getAllTags(filePath);
      if (tag != null) return true;
    } catch (e) {
      // Ignore
    }

    // Check fallback availability
    return await File('scripts/write_lyrics.py').exists();
  }
}
