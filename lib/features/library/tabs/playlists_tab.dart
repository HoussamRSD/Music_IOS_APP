import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/data/models/playlist.dart';
import '../../playlists/services/playlist_service.dart';
import '../../playlists/playlist_detail_screen.dart';

class PlaylistsTab extends ConsumerWidget {
  const PlaylistsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);
    final topPadding =
        MediaQuery.of(context).padding.top + kMinInteractiveDimensionCupertino;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(top: topPadding),
          sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
        ),
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            ref.invalidate(playlistsProvider);
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: CupertinoButton(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              onPressed: () => _showCreatePlaylistDialog(context, ref),
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
            ),
          ),
        ),
        playlistsAsync.when(
          data: (playlists) {
            if (playlists.isEmpty) {
              return const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No playlists yet',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final playlist = playlists[index];
                return _PlaylistTile(playlist: playlist);
              }, childCount: playlists.length),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(
              child: CupertinoActivityIndicator(color: Colors.white),
            ),
          ),
          error: (error, stack) => SliverFillRemaining(
            child: Center(
              child: Text(
                'Error loading playlists',
                style: const TextStyle(color: Colors.white54),
              ),
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
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
                await ref
                    .read(playlistServiceProvider)
                    .createPlaylist(textController.text);
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

class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;

  const _PlaylistTile({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            CupertinoIcons.music_albums,
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(
          playlist.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${0} songs', // TODO: Get song count
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          CupertinoIcons.chevron_right,
          color: Colors.white54,
          size: 20,
        ),
        onTap: () {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => PlaylistDetailScreen(playlist: playlist),
            ),
          );
        },
      ),
    );
  }
}
