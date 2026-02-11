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

  Future<List<MuxedStreamInfo>> getVideoQualities(String videoId) async {
    // Create a local instance to avoid shared state issues/crashes
    final yt = YoutubeExplode();
    try {
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      return manifest.muxed.sortByVideoQuality();
    } catch (e) {
      debugPrint('Error fetching qualities: $e');
      return [];
    } finally {
      yt.close();
    }
  }

  Future<bool> downloadVideo(
    String videoId, {
    bool isAudioOnly = true,
    bool safeMode = false,
    String? qualityLabel,
  }) async {
    try {
      // 1. Get Video Info
      final video = await _yt.videos.get(videoId);
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);

      StreamInfo streamInfo;
      String extension;

      if (isAudioOnly) {
        streamInfo = manifest.audioOnly.withHighestBitrate();
        extension = 'm4a';
      } else {
        // Video Mode: Find requested quality or best muxed
        final muxed = manifest.muxed;
        if (qualityLabel != null) {
          streamInfo = muxed.firstWhere(
            (s) => s.videoQuality.toString() == qualityLabel,
            orElse: () => muxed.withHighestBitrate(),
          );
        } else {
          streamInfo = muxed.withHighestBitrate();
        }
        extension = 'mp4';
      }

      // 2. Prepare Directory
      final appDir = await getApplicationDocumentsDirectory();
      // Use lowercase 'music' to match LibraryScannerService
      // Subfolder based on type
      final folder = isAudioOnly ? 'Downloads' : 'Videos';
      final downloadDir = Directory('${appDir.path}/music/$folder');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // 3. Download to Temp File
      final stream = _yt.videos.streamsClient.get(streamInfo);
      final tempFilePath = '${downloadDir.path}/${video.id}.$extension';
      final file = File(tempFilePath);
      final fileStream = file.openWrite();
      await stream.pipe(fileStream);
      await fileStream.flush();
      await fileStream.close();

      String finalFileName;

      if (isAudioOnly) {
        // --- AUDIO LOGIC (Smart vs Safe) ---
        var title = video.title;
        var artist = video.author;
        var album = "YouTube";
        var artworkUrl = video.thumbnails.highResUrl;
        String? lyrics;

        if (!safeMode) {
          // Clean artist name for better search results
          var searchArtist = artist
              .replaceAll(
                RegExp(r' - Topic$|VEVO|Official', caseSensitive: false),
                '',
              )
              .trim();

          // SMART MODE: Identify & Fetch Metadata
          final metadata = await _identifySong('$title $searchArtist');
          if (metadata != null) {
            title = metadata['title'];
            artist = metadata['artist'];
            album = metadata['album'];
            artworkUrl = metadata['artwork_url'].replaceAll(
              '100x100',
              '600x600',
            );
          }

          // Fetch Lyrics
          try {
            final lrclib = _ref.read(lrclibServiceProvider);
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
            debugPrint("Lyrics Error: $e");
          }
        }

        // Tagging
        await _tagFile(tempFilePath, title, artist, album, artworkUrl, lyrics);

        // Rename
        final cleanTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
        final cleanArtist = artist.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
        finalFileName = '$cleanArtist - $cleanTitle.m4a';
      } else {
        // --- VIDEO LOGIC (Simple Rename) ---
        final cleanTitle = video.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
        finalFileName = '$cleanTitle.$extension';
      }

      // 4. Move to Final Path
      final finalPath = '${downloadDir.path}/$finalFileName';
      if (tempFilePath != finalPath) {
        // Ensure unique name
        String uniquePath = finalPath;
        int counter = 1;
        while (await File(uniquePath).exists()) {
          uniquePath =
              '${downloadDir.path}/${finalFileName.replaceAll(".$extension", "")} ($counter).$extension';
          counter++;
        }
        await file.rename(uniquePath);
      }

      // 5. Trigger Library Scan
      final scanner = _ref.read(libraryScannerServiceProvider);
      await scanner.scanLibrary();

      return true;
    } catch (e) {
      debugPrint("Download Error: $e");
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
        debugPrint("Cover download error: $e");
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
      debugPrint("Tagging Error: $e");
    }
  }
}

final downloadServiceProvider = Provider((ref) => DownloadService(ref));
