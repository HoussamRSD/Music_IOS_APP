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
    try {
      // Read existing metadata
      final tag = await _tagger.getAllTags(filePath);
      // Note: If reading fails (e.g. file locked), we can't preserve tags.
      // But we can try to write anyway if we accept risk, or fail.
      if (tag == null) {
        developer.log(
          'Could not read tags for $filePath. File might be locked or corrupt.',
          name: 'LyricsWriterService',
        );
        return false;
      }

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

      return true;
    } catch (e) {
      developer.log(
        'Error writing plain lyrics: $e',
        name: 'LyricsWriterService',
      );
      return false;
    }
  }

  /// Write synced LRC lyrics to audio file
  /// Note: This writes LRC as plain text to USLT frame
  /// Some players may parse it as synced lyrics
  Future<bool> writeSyncedLyrics(String filePath, String lrcContent) async {
    try {
      // Read existing metadata
      final tag = await _tagger.getAllTags(filePath);
      if (tag == null) return false;

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

      return true;
    } catch (e) {
      developer.log(
        'Error writing synced lyrics: $e',
        name: 'LyricsWriterService',
      );
      return false;
    }
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
  Future<bool> canWriteToFile(String filePath) async {
    try {
      final tag = await _tagger.getAllTags(filePath);
      return tag != null;
    } catch (e) {
      return false;
    }
  }
}
