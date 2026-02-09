import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../ui/components/glass_container.dart';
import '../services/youtube_service.dart';
import '../models/youtube_video.dart';
import '../../player/services/audio_player_service.dart';

final youtubeSearchQueryProvider = StateProvider<String>((ref) => '');

final youtubeSearchResultsProvider = FutureProvider<List<YouTubeVideo>>((
  ref,
) async {
  final query = ref.watch(youtubeSearchQueryProvider);
  if (query.isEmpty) return [];

  final service = ref.read(youtubeServiceProvider);
  return await service.search(query);
});

class YouTubeTab extends ConsumerWidget {
  const YouTubeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(youtubeSearchResultsProvider);
    final query = ref.watch(youtubeSearchQueryProvider);
    // Controller removed as it was unused and caused lint errors

    // Ensure controller cursor is at end when text changes if needed,
    // but using a controller with watch inside build can be tricky.
    // Better to use a simpler approach for the search bar or manageable state.
    // We will use onSubmitted for now to trigger search.

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        middle: Text('YouTube'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CupertinoSearchTextField(
                placeholder: 'Search YouTube',
                style: const TextStyle(color: AppTheme.textPrimary),
                onSubmitted: (value) {
                  ref.read(youtubeSearchQueryProvider.notifier).state = value;
                },
              ),
            ),
            Expanded(
              child: searchResults.when(
                data: (videos) {
                  if (videos.isEmpty) {
                    if (query.isEmpty) {
                      return const Center(
                        child: Text(
                          'Search for songs on YouTube',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      );
                    }
                    return const Center(
                      child: Text(
                        'No results found',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final video = videos[index];
                      return _YouTubeVideoTile(video: video);
                    },
                  );
                },
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (err, stack) => Center(
                  child: Text(
                    'Error: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YouTubeVideoTile extends ConsumerWidget {
  final YouTubeVideo video;

  const _YouTubeVideoTile({required this.video});

  Future<void> _playVideo(BuildContext context, WidgetRef ref) async {
    final service = ref.read(youtubeServiceProvider);
    final audioUrl = await service.getAudioStreamUrl(video.id);

    if (audioUrl != null) {
      ref
          .read(audioPlayerServiceProvider.notifier)
          .playYouTubeVideo(
            audioUrl,
            video.title,
            video.author,
            video.thumbnailUrl,
          );
    } else {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Could not load audio stream.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _playVideo(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.transparent,
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                video.thumbnailUrl,
                width: 80,
                height: 45,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 45,
                  color: Colors.grey[800],
                  child: const Icon(
                    CupertinoIcons.music_note,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Duration
            Text(
              _formatDuration(video.duration),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
