import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/youtube_video.dart';

class YouTubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  Future<List<YouTubeVideo>> search(String query) async {
    try {
      final searchResults = await _yt.search.search(query);
      return searchResults
          .map(
            (video) => YouTubeVideo(
              id: video.id.value,
              title: video.title,
              author: video.author,
              duration: video.duration ?? Duration.zero,
              thumbnailUrl: video.thumbnails.lowResUrl,
            ),
          )
          .toList();
    } catch (e) {
      // Handle search error
      return [];
    }
  }

  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioOnly = manifest.audioOnly;
      final audioStream = audioOnly.withHighestBitrate();
      return audioStream.url.toString();
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _yt.close();
  }
}

final youtubeServiceProvider = Provider<YouTubeService>((ref) {
  final service = YouTubeService();
  ref.onDispose(() => service.dispose());
  return service;
});
