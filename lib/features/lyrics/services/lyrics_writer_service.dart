import 'dart:developer' as developer;
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
      final tag = await _tagger.getAllTags(filePath);
      return tag?.lyrics;
    } catch (e) {
      developer.log(
        'Error reading embedded lyrics: $e',
        name: 'LyricsWriterService',
      );
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
