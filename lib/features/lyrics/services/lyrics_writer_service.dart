import 'package:flutter_audio_tagger/flutter_audio_tagger.dart';

/// Service for writing lyrics to audio file metadata
class LyricsWriterService {
  final FlutterAudioTagger _tagger = FlutterAudioTagger();

  /// Write plain text lyrics to audio file USLT frame
  Future<bool> writePlainLyrics(String filePath, String lyrics) async {
    try {
      // Read existing metadata
      final audioData = await _tagger.readAudioFileData(filePath);

      // Update lyrics field
      final updatedData = audioData.copyWith(lyrics: lyrics);

      // Write back to file
      await _tagger.writeAudioFileData(
        filePath: filePath,
        audioFileData: updatedData,
      );

      return true;
    } catch (e) {
      print('Error writing plain lyrics: $e');
      return false;
    }
  }

  /// Write synced LRC lyrics to audio file
  /// Note: This writes LRC as plain text to USLT frame
  /// Some players may parse it as synced lyrics
  Future<bool> writeSyncedLyrics(String filePath, String lrcContent) async {
    try {
      // Read existing metadata
      final audioData = await _tagger.readAudioFileData(filePath);

      // Write LRC content as lyrics
      final updatedData = audioData.copyWith(lyrics: lrcContent);

      // Write back to file
      await _tagger.writeAudioFileData(
        filePath: filePath,
        audioFileData: updatedData,
      );

      return true;
    } catch (e) {
      print('Error writing synced lyrics: $e');
      return false;
    }
  }

  /// Read embedded lyrics from audio file
  Future<String?> readEmbeddedLyrics(String filePath) async {
    try {
      final audioData = await _tagger.readAudioFileData(filePath);
      return audioData.lyrics;
    } catch (e) {
      print('Error reading embedded lyrics: $e');
      return null;
    }
  }

  /// Check if file is writable
  Future<bool> canWriteToFile(String filePath) async {
    try {
      final audioData = await _tagger.readAudioFileData(filePath);
      return audioData != null;
    } catch (e) {
      return false;
    }
  }
}
