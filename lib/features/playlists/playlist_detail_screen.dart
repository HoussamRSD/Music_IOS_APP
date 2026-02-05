import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models/playlist.dart';
import '../../../core/data/models/song.dart';
import '../../../core/theme/app_theme.dart';
import '../player/services/audio_player_service.dart';
import '../player/services/queue_service.dart';
import 'services/playlist_service.dart';

final playlistSongsProvider = FutureProvider.family<List<Song>, int>((
  ref,
  playlistId,
) async {
  return ref.watch(playlistServiceProvider).getSongs(playlistId);
});

class PlaylistDetailScreen extends ConsumerWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(playlistSongsProvider(playlist.id!));

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.backgroundColor,
        middle: Text(
          playlist.name,
          style: const TextStyle(color: Colors.white),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: songsAsync.when(
          data: (songs) {
            if (songs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.music_albums,
                      size: 64,
                      color: Colors.white24,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Empty Playlist',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Play Button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CupertinoButton(
                    color: AppTheme.primaryColor,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.play_fill),
                        SizedBox(width: 8),
                        Text('Play All'),
                      ],
                    ),
                    onPressed: () {
                      ref
                          .read(queueControllerProvider.notifier)
                          .setQueue(songs);
                      if (songs.isNotEmpty) {
                        ref
                            .read(audioPlayerServiceProvider.notifier)
                            .playSong(songs.first);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: CupertinoListTile(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: song.artworkPath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.asset(
                                    song.artworkPath!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _defaultArtwork(),
                                  ),
                                )
                              : _defaultArtwork(),
                          title: Text(
                            song.title,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            song.artists.join(', '),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                          trailing: CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: const Icon(
                              CupertinoIcons.minus_circle,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              await ref
                                  .read(playlistServiceProvider)
                                  .removeSong(playlist.id!, song);
                              ref.invalidate(
                                playlistSongsProvider(playlist.id!),
                              );
                            },
                          ),
                          onTap: () {
                            ref
                                .read(queueControllerProvider.notifier)
                                .setQueue(songs, startIndex: index);
                            ref
                                .read(audioPlayerServiceProvider.notifier)
                                .playSong(song);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CupertinoActivityIndicator(color: Colors.white),
          ),
          error: (error, stack) => const Center(
            child: Text('Error', style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _defaultArtwork() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(
        CupertinoIcons.music_note,
        color: Colors.white54,
        size: 20,
      ),
    );
  }
}
