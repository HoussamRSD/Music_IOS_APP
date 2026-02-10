import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Service for executing yt-dlp commands
/// Allows direct audio download from YouTube with metadata enrichment
class YtDlpService {
  /// Check if yt-dlp is available on the system
  Future<bool> isYtDlpAvailable() async {
    try {
      final result = await Process.run('yt-dlp', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Download video from YouTube using yt-dlp
  /// Returns the file path if successful, null otherwise
  Future<String?> downloadVideo(
    String videoId, {
    required String title,
    required String artist,
    required bool smartMode,
  }) async {
    try {
      // Check if yt-dlp is available
      final isAvailable = await isYtDlpAvailable();
      if (!isAvailable) {
        throw Exception(
          'yt-dlp is not installed. Please install it using: pip install yt-dlp',
        );
      }

      // Prepare download directory
      final appDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${appDir.path}/music/Downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // Build yt-dlp command arguments
      final ytDlpUrl = 'https://www.youtube.com/watch?v=$videoId';
      final outputTemplate = '${downloadDir.path}/%(title)s.%(ext)s';

      final args = [
        '-f',
        'bestaudio[ext=m4a]/bestaudio',
        '--extract-audio',
        '--audio-format',
        'm4a',
        '--audio-quality',
        '0',
        '--embed-thumbnail',
        '--embed-metadata',
        '-o',
        outputTemplate,
        '--newline',
        ytDlpUrl,
      ];

      // Add smart mode specific flags
      if (!smartMode) {
        // Safe mode: just download, no processing
        args.add('--no-post-overwrites');
      }

      // Execute yt-dlp
      final process = await Process.start('yt-dlp', args);

      // Capture output
      final lines = <String>[];
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            lines.add(line);
            print('[yt-dlp] $line');
          });

      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            print('[yt-dlp ERROR] $line');
          });

      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        throw Exception('yt-dlp process exited with code $exitCode');
      }

      // Find the downloaded file
      final files =
          downloadDir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.m4a'))
              .toList()
            ..sort(
              (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
            );

      if (files.isEmpty) {
        throw Exception('No audio file found after download');
      }

      return files.first.path;
    } catch (e) {
      print('YtDlp Error: $e');
      return null;
    }
  }

  /// Stream download progress updates
  /// Useful for UI progress indicators
  Stream<DownloadProgress> downloadWithProgress(String videoId) async* {
    try {
      final isAvailable = await isYtDlpAvailable();
      if (!isAvailable) {
        yield DownloadProgress(
          progress: 0,
          status: 'yt-dlp not installed',
          isError: true,
        );
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${appDir.path}/music/Downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final ytDlpUrl = 'https://www.youtube.com/watch?v=$videoId';
      final outputTemplate = '${downloadDir.path}/%(title)s.%(ext)s';

      final args = [
        '-f',
        'bestaudio[ext=m4a]/bestaudio',
        '--extract-audio',
        '--audio-format',
        'm4a',
        '--audio-quality',
        '0',
        '--embed-thumbnail',
        '--embed-metadata',
        '-o',
        outputTemplate,
        '--newline',
        ytDlpUrl,
      ];

      final process = await Process.start('yt-dlp', args);

      // Parse progress from output
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            final progressRegex = RegExp(r'(\d+\.\d+)%.*of.*at');
            final match = progressRegex.firstMatch(line);

            if (match != null) {
              final progress = double.parse(match.group(1)!) / 100.0;
              // yield DownloadProgress(progress: progress, status: line);
            }

            if (line.contains('[download]') && line.contains('100%')) {
              // yield DownloadProgress(progress: 1.0, status: 'Download complete');
            }
          });

      await process.exitCode;
    } catch (e) {
      print('Error: $e');
      yield DownloadProgress(progress: 0, status: 'Error: $e', isError: true);
    }
  }
}

class DownloadProgress {
  final double progress; // 0.0 to 1.0
  final String status;
  final bool isError;

  DownloadProgress({
    required this.progress,
    required this.status,
    this.isError = false,
  });
}

final ytDlpServiceProvider = Provider((ref) => YtDlpService());
