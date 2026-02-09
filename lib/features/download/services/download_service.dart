import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:flutter_audio_tagger/flutter_audio_tagger.dart';
import 'package:flutter_audio_tagger/tag.dart';
import 'dart:convert';
import '../../lyrics/services/lrclib_service.dart';
import '../../library/providers/library_providers.dart';

class DownloadService {
  final YoutubeExplode _yt = YoutubeExplode();
  final Ref _ref;
  final FlutterAudioTagger _tagger = FlutterAudioTagger();

  DownloadService(this._ref);

  Future<bool> downloadVideo(String videoId, {bool safeMode = false}) async {
    try {
      // 1. Get Video & Stream Info
      final video = await _yt.videos.get(videoId);
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioStreamInfo = manifest.audioOnly.withHighestBitrate();

      // 2. Prepare Directory
      final appDir = await getApplicationDocumentsDirectory();
      // Use lowercase 'music' to match LibraryScannerService
      final downloadDir = Directory('${appDir.path}/music/Downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // 3. Download to Temp File
      final stream = _yt.videos.streamsClient.get(audioStreamInfo);
      final tempFilePath = '${downloadDir.path}/${video.id}.m4a';
      final file = File(tempFilePath);
      final fileStream = file.openWrite();
      await stream.pipe(fileStream);
      await fileStream.flush();
      await fileStream.close();

      // 4. Metadata & Renaming
      var title = video.title;
      var artist = video.author;
      var album = "YouTube";
      var artworkUrl = video.thumbnails.highResUrl;
      String? lyrics;

      if (!safeMode) {
        final metadata = await _identifySong(title); // iTunes search
        if (metadata != null) {
          title = metadata['title'];
          artist = metadata['artist'];
          album = metadata['album'];
          artworkUrl = metadata['artwork_url'].replaceAll('100x100', '600x600');
        }

        // Fetch Lyrics
        try {
          final lrclib = _ref.read(lrclibServiceProvider);

          // Calculate duration if available
          int? duration;
          if (video.duration != null) {
            duration = video.duration!.inSeconds;
          }

          final result = await lrclib.searchLyrics(
            trackName: title,
            artistName: artist,
            albumName: album,
            durationSeconds: duration,
          );

          if (result != null) {
            lyrics = result.syncedLyrics ?? result.plainLyrics;
          }
        } catch (e) {
          print("Lyrics Error: $e");
        }
      }

      // 5. Tagging
      await _tagFile(tempFilePath, title, artist, album, artworkUrl, lyrics);

      // 6. Rename/Move to final path
      final cleanTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
      final cleanArtist = artist.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
      final finalFileName = '$cleanArtist - $cleanTitle.m4a';
      final finalPath = '${downloadDir.path}/$finalFileName';

      if (tempFilePath != finalPath) {
        await file.rename(finalPath);
      }

      // 7. Trigger Library Scan
      final scanner = _ref.read(libraryScannerServiceProvider);
      await scanner.scanLibrary();

      return true;
    } catch (e) {
      print("Download Error: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> _identifySong(String query) async {
    try {
      // Simple iTunes Search
      final uri = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&entity=song&limit=1',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['resultCount'] > 0) {
          final item = data['results'][0];
          return {
            'title': item['trackName'],
            'artist': item['artistName'],
            'album': item['collectionName'],
            'artwork_url': item['artworkUrl100'],
          };
        }
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  Future<void> _tagFile(
    String filePath,
    String title,
    String artist,
    String album,
    String artworkUrl,
    String? lyrics,
  ) async {
    try {
      final tempDir = await getTemporaryDirectory();
      String? artPath;

      // Download Cover
      try {
        final response = await http.get(Uri.parse(artworkUrl));
        if (response.statusCode == 200) {
          artPath = '${tempDir.path}/temp_cover.jpg';
          await File(artPath).writeAsBytes(response.bodyBytes);
        }
      } catch (e) {
        print("Cover download error: $e");
      }

      Uint8List? artworkBytes;
      if (artPath != null) {
        try {
          artworkBytes = await File(artPath).readAsBytes();
        } catch (e) {}
      }

      final tag = Tag(
        title: title,
        artist: artist,
        album: album,
        lyrics: lyrics,
        artwork: artworkBytes,
      );

      await _tagger.editTags(tag, filePath);
    } catch (e) {
      print("Tagging Error: $e");
    }
  }
}

final downloadServiceProvider = Provider((ref) => DownloadService(ref));
