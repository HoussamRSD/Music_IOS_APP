import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models/song.dart';
import '../../../core/theme/app_theme.dart';
import '../../../ui/components/glass_container.dart';
import '../../player/services/audio_player_service.dart';
import '../../player/services/queue_service.dart';
import '../data/song_repository.dart';

// Provider for favorites list
final favoriteSongsProvider = FutureProvider<List<Song>>((ref) async {
  final repository = ref.watch(songRepositoryProvider);
  return await repository.getFavoriteSongs();
});

class FavoritesTab extends ConsumerWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteSongsProvider);
    final topPadding =
        MediaQuery.of(context).padding.top + kMinInteractiveDimensionCupertino;

    return favoritesAsync.when(
      data: (favorites) {
        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.heart, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No favorites yet', style: AppTheme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Tap the heart icon on any song\nto add it to your favorites',
                  style: AppTheme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(top: topPadding + 8, bottom: 120),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final song = favorites[index];
            return _FavoriteSongTile(song: song);
          },
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
            Text(
              'Error loading favorites',
              style: AppTheme.textTheme.titleLarge,
            ),
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

class _FavoriteSongTile extends ConsumerWidget {
  final Song song;

  const _FavoriteSongTile({required this.song});

  String _formatDuration(int? milliseconds) {
    if (milliseconds == null) return '';
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: BorderRadius.circular(12),
      opacity: 0.2,
      blur: 15,
      child: CupertinoListTile(
        padding: const EdgeInsets.all(12),
        leading: song.artworkPath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(song.artworkPath!),
                  width: 50,
                  height: 50,
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
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          song.artists.isNotEmpty ? song.artists.join(', ') : 'Unknown Artist',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
          ),
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
              child: const Icon(
                CupertinoIcons.heart_fill,
                color: Colors.red,
                size: 24,
              ),
              onPressed: () async {
                // Remove from favorites
                await ref
                    .read(songRepositoryProvider)
                    .toggleFavorite(song.id!, false);
                ref.invalidate(favoriteSongsProvider);
              },
            ),
          ],
        ),
        onTap: () {
          // Play the song
          final allFavorites = ref.read(favoriteSongsProvider).value ?? [];
          final songIndex = allFavorites.indexWhere((s) => s.id == song.id);

          ref
              .read(queueControllerProvider.notifier)
              .setQueue(
                allFavorites,
                startIndex: songIndex >= 0 ? songIndex : 0,
              );

          ref.read(audioPlayerServiceProvider.notifier).playSong(song);
        },
      ),
    );
  }

  Widget _defaultArtwork() {
    return Container(
      width: 50,
      height: 50,
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
