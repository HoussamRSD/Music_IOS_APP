import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models/song.dart';
import '../../../core/theme/app_theme.dart';
import '../../artists/providers/artist_provider.dart';
import '../../settings/providers/font_provider.dart';
import '../../player/services/audio_player_service.dart';
import '../../player/services/queue_service.dart';

class ArtistDetailsScreen extends ConsumerWidget {
  final String artistName;

  const ArtistDetailsScreen({super.key, required this.artistName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = ref.watch(artistSongsProvider(artistName));
    final appTextStyles = ref.watch(appTextStylesProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.backgroundColor.withValues(alpha: 0.8),
        middle: Text(artistName, style: appTextStyles.titleMedium()),
        previousPageTitle: 'Artists',
      ),
      child: songs.isEmpty
          ? Center(
              child: Text(
                'No songs found',
                style: appTextStyles.bodyMedium().copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 100, 0, 100),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return _ArtistSongTile(
                  song: song,
                  onTap: () {
                    // Create a queue starting from this song, but including all songs by this artist
                    ref
                        .read(queueControllerProvider.notifier)
                        .setQueue(songs, startIndex: index);
                    ref
                        .read(audioPlayerServiceProvider.notifier)
                        .playSong(song);
                  },
                );
              },
            ),
    );
  }
}

class _ArtistSongTile extends ConsumerWidget {
  final Song song;
  final VoidCallback onTap;

  const _ArtistSongTile({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTextStyles = ref.watch(appTextStylesProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Artwork
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 50,
                  height: 50,
                  color: AppTheme.surfaceColor,
                  child: song.artworkPath != null
                      ? Image.file(
                          File(song.artworkPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            CupertinoIcons.music_note,
                            color: AppTheme.textSecondary,
                          ),
                        )
                      : const Icon(
                          CupertinoIcons.music_note,
                          color: AppTheme.textSecondary,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: appTextStyles.bodyMedium(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.album ?? 'Unknown Album',
                      style: appTextStyles.bodySmall().copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                _formatDuration(song.duration ?? 0),
                style: appTextStyles.bodySmall().copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
