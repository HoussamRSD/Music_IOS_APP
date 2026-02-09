import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models/song.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../ui/components/glass_container.dart';
import '../../../ui/components/tab_header.dart';
import '../../player/services/audio_player_service.dart';
import '../../player/services/queue_service.dart';
import '../../playlists/components/add_to_playlist_sheet.dart';
import '../data/song_repository.dart';
import '../providers/library_providers.dart';
import '../../settings/providers/font_provider.dart';
import '../tabs/favorites_tab.dart'; // For favoriteSongsProvider invalidation

class SongsTab extends ConsumerWidget {
  const SongsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songsProvider);
    final isGridView = ref.watch(isGridViewProvider);

    return songsAsync.when(
      data: (songs) {
        if (songs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.music_note_2,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text('No songs yet', style: AppTheme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Import your music files to get started',
                  style: AppTheme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (isGridView) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    TabHeader(
                      title: 'Songs',
                      icon: CupertinoIcons.music_note_2,
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 180),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = songs[index];
                      return SongGridTile(song: song);
                    },
                    childCount: songs.length,
                  ),
                ),
              ),
            ],
          );
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  TabHeader(
                    title: 'Songs',
                    icon: CupertinoIcons.music_note_2,
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 180),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = songs[index];
                    return SongListTile(song: song);
                  },
                  childCount: songs.length,
                ),
              ),
            ),
          ],
        );
      },
      loading: () =>
          const Center(child: CupertinoActivityIndicator(color: Colors.white)),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text('Error loading songs', style: AppTheme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: AppTheme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class SongListTile extends ConsumerWidget {
  final Song song;

  const SongListTile({super.key, required this.song});

  String _formatDuration(int? milliseconds) {
    if (milliseconds == null) return '';
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFont = ref.watch(fontProvider).fontFamily;
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: BorderRadius.circular(12),
      opacity: 0.2, // Slightly more opaque for list items to be readable
      blur: 15,
      child: CupertinoListTile(
        padding: const EdgeInsets.all(12),
        leading: song.artworkPath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(song.artworkPath!),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _defaultArtwork(),
                ),
              )
            : _defaultArtwork(),
        title: Text(
          song.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ).withAppFont(selectedFont),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          song.artists.isNotEmpty ? song.artists.join(', ') : 'Unknown Artist',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
          ).withAppFont(selectedFont),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatDuration(song.duration),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 32,
              child: Icon(
                song.isFavorite
                    ? CupertinoIcons.heart_fill
                    : CupertinoIcons.heart,
                color: song.isFavorite ? Colors.red : Colors.white,
                size: 22,
              ),
              onPressed: () async {
                await ref
                    .read(songRepositoryProvider)
                    .toggleFavorite(song.id!, !song.isFavorite);
                ref.invalidate(songsProvider);
                ref.invalidate(favoriteSongsProvider);
              },
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.ellipsis, color: Colors.white),
              onPressed: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (context) => CupertinoActionSheet(
                    actions: [
                      CupertinoActionSheetAction(
                        child: const Text('Add to Playlist'),
                        onPressed: () {
                          Navigator.pop(context);
                          showCupertinoModalPopup(
                            context: context,
                            builder: (context) =>
                                AddToPlaylistSheet(song: song),
                          );
                        },
                      ),
                    ],
                    cancelButton: CupertinoActionSheetAction(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        onTap: () {
          // Set the queue to all songs and play the selected one
          final allSongs = ref.read(songsProvider).value ?? [];
          final songIndex = allSongs.indexWhere((s) => s.id == song.id);

          ref
              .read(queueControllerProvider.notifier)
              .setQueue(allSongs, startIndex: songIndex >= 0 ? songIndex : 0);

          // Play the song
          ref.read(audioPlayerServiceProvider.notifier).playSong(song);
        },
      ),
    );
  }

  Widget _defaultArtwork() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        CupertinoIcons.music_note,
        color: AppTheme.primaryColor,
        size: 24,
      ),
    );
  }
}

class SongGridTile extends ConsumerWidget {
  final Song song;

  const SongGridTile({super.key, required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(audioPlayerServiceProvider.notifier).playSong(song);
        ref.read(queueControllerProvider.notifier).setQueue([
          song,
        ]); // Simplified queue logic for grid
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GlassContainer(
              borderRadius: BorderRadius.circular(12),
              opacity: 0.1,
              blur: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: song.artworkPath != null
                    ? Image.file(
                        File(song.artworkPath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            _defaultArtwork(),
                      )
                    : _defaultArtwork(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            song.title,
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            song.artists.join(', '),
            style: AppTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _defaultArtwork() {
    return Container(
      color: AppTheme.surfaceHighlight,
      child: Center(
        child: Icon(
          CupertinoIcons.music_note,
          color: AppTheme.textSecondary,
          size: 40,
        ),
      ),
    );
  }
}
