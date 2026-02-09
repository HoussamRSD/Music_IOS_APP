import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../ui/components/tab_header.dart';
import '../services/youtube_service.dart';
import '../models/youtube_video.dart';
import '../../player/services/audio_player_service.dart';
import '../../download/services/download_service.dart';

class YouTubeSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) {
    state = value;
  }
}

final youtubeSearchQueryProvider =
    NotifierProvider<YouTubeSearchQueryNotifier, String>(
      YouTubeSearchQueryNotifier.new,
    );

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
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: TabHeader(
                title: 'YouTube',
                icon: CupertinoIcons.play_rectangle_fill,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CupertinoSearchTextField(
                  placeholder: 'Search YouTube',
                  style: const TextStyle(color: AppTheme.textPrimary),
                  onSubmitted: (value) {
                    ref.read(youtubeSearchQueryProvider.notifier).update(value);
                  },
                ),
              ),
            ),
            searchResults.when(
              data: (videos) {
                if (videos.isEmpty) {
                  if (query.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'Search for songs on YouTube',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    );
                  }
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No results found',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.only(bottom: 180),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final video = videos[index];
                        return _YouTubeVideoTile(video: video);
                      },
                      childCount: videos.length,
                    ),
                  ),
                );
              },
              loading: () => SliverFillRemaining(
                child: Center(child: CupertinoActivityIndicator()),
              ),
              error: (err, stack) => SliverFillRemaining(
                child: Center(
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

class _YouTubeVideoTile extends ConsumerStatefulWidget {
  final YouTubeVideo video;

  const _YouTubeVideoTile({required this.video});

  @override
  ConsumerState<_YouTubeVideoTile> createState() => _YouTubeVideoTileState();
}

class _YouTubeVideoTileState extends ConsumerState<_YouTubeVideoTile> {
  bool _isDownloading = false;

  Future<void> _playVideo() async {
    final service = ref.read(youtubeServiceProvider);
    final audioUrl = await service.getAudioStreamUrl(widget.video.id);

    if (audioUrl != null) {
      ref
          .read(audioPlayerServiceProvider.notifier)
          .playYouTubeVideo(
            audioUrl,
            widget.video.title,
            widget.video.author,
            widget.video.thumbnailUrl,
          );
    } else {
      if (mounted) {
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

  Future<void> _downloadVideo() async {
    setState(() => _isDownloading = true);

    // Show Toast/Snackbar
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Starting download...')));

    final downloadService = ref.read(downloadServiceProvider);
    final success = await downloadService.downloadVideo(widget.video.id);

    if (mounted) {
      setState(() => _isDownloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Download complete!' : 'Download failed.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _playVideo,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.transparent,
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.video.thumbnailUrl,
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
                    widget.video.title,
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
                    widget.video.author,
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
            // Duration & Download
            Row(
              children: [
                Text(
                  _formatDuration(widget.video.duration),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                if (_isDownloading)
                  const CupertinoActivityIndicator(radius: 8)
                else
                  GestureDetector(
                    onTap: _downloadVideo,
                    child: const Icon(
                      CupertinoIcons.cloud_download,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
              ],
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
