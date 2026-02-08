import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models/song.dart';
import '../../core/theme/app_theme.dart';
import '../library/services/file_import_service.dart';
import '../library/data/song_repository.dart';
import '../player/services/audio_player_service.dart';
import '../player/services/queue_service.dart';
import '../playlists/components/add_to_playlist_sheet.dart';
import 'tabs/playlists_tab.dart';

// Provider for songs list
final songsProvider = FutureProvider<List<Song>>((ref) async {
  final repository = ref.watch(songRepositoryProvider);
  return await repository.getAllSongs();
});

// Provider for view mode
final isGridViewProvider = StateProvider<bool>((ref) => false);

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _selectedSegment = 0;

  Future<void> _importFiles() async {
    try {
      final importService = ref.read(fileImportServiceProvider);
      final songs = await importService.importFiles();

      if (!mounted) return;

      if (songs.isEmpty) {
        return;
      }

      // Refresh the songs list
      ref.invalidate(songsProvider);

      // Show success message
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Import Complete'),
          content: Text('Successfully imported ${songs.length} song(s)'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Import Failed'),
          content: Text('An error occurred while importing files: $e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGridView = ref.watch(isGridViewProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        middle: CupertinoSlidingSegmentedControl<int>(
          backgroundColor: AppTheme.surfaceColor.withValues(alpha: 0.2),
          thumbColor: AppTheme.surfaceColor,
          groupValue: _selectedSegment,
          children: const {
            0: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Songs', style: TextStyle(color: Colors.white)),
            ),
            1: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Playlists', style: TextStyle(color: Colors.white)),
            ),
          },
          onValueChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedSegment = value;
              });
            }
          },
        ),
        backgroundColor: Colors.transparent,
        leading: _selectedSegment == 0
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(
                  isGridView
                      ? CupertinoIcons.list_bullet
                      : CupertinoIcons.square_grid_2x2,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                onPressed: () {
                  ref.read(isGridViewProvider.notifier).state = !isGridView;
                },
              )
            : null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _importFiles,
          child: const Icon(
            CupertinoIcons.add_circled_solid,
            color: AppTheme.primaryColor,
            size: 32,
          ),
        ),
      ),
      child: _selectedSegment == 0 ? const _SongsTab() : const PlaylistsTab(),
    );
  }
}

class _SongsTab extends ConsumerWidget {
  const _SongsTab();

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
                const SizedBox(height: 24),
                CupertinoButton.filled(
                  onPressed: () {
                    // Get the parent state to call _importFiles
                    final libraryState = context
                        .findAncestorStateOfType<_LibraryScreenState>();
                    libraryState?._importFiles();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(CupertinoIcons.add, size: 20),
                      SizedBox(width: 8),
                      Text('Import Music'),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        if (isGridView) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return _SongGridTile(song: song);
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 120), // Space for bottom nav
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return _SongListTile(song: song);
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

class _SongListTile extends ConsumerWidget {
  final Song song;

  const _SongListTile({required this.song});

  String _formatDuration(int? milliseconds) {
    if (milliseconds == null) return '';
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
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

class _SongGridTile extends ConsumerWidget {
  final Song song;

  const _SongGridTile({required this.song});

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
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.surfaceHighlight,
              ),
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
