import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/models/song.dart';
import '../../../../core/theme/app_theme.dart';
import '../../playlists/services/playlist_service.dart';

class AddToPlaylistSheet extends ConsumerWidget {
  final Song song;

  const AddToPlaylistSheet({super.key, required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Add to Playlist',
              style: AppTheme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: playlistsAsync.when(
              data: (playlists) {
                if (playlists.isEmpty) {
                  return Center(
                    child: Text(
                      'No playlists',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return CupertinoListTile(
                      leading: Icon(
                        CupertinoIcons.music_albums,
                        color: AppTheme.primaryColor,
                      ),
                      title: Text(
                        playlist.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        ref.read(playlistServiceProvider).addSongsToPlaylist(
                          playlist.id!,
                          [song],
                        );

                        // Close sheet and show confirmation
                        Navigator.pop(context);

                        // Optional: Show toast/snackbar
                      },
                    );
                  },
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoButton(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.add, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'New Playlist',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showCreatePlaylistDialog(context, ref);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('New Playlist'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: textController,
            placeholder: 'Playlist Name',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Create'),
            onPressed: () async {
              if (textController.text.isNotEmpty) {
                final playlistId = await ref
                    .read(playlistServiceProvider)
                    .createPlaylist(textController.text);

                // Add the song to the new playlist
                if (playlistId != null) {
                  await ref.read(playlistServiceProvider).addSongsToPlaylist(
                    playlistId,
                    [song],
                  );
                }

                ref.invalidate(playlistsProvider);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              }
            },
          ),
        ],
      ),
    );
  }
}
