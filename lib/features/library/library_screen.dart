import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models/song.dart';
import '../../core/theme/app_theme.dart';
import '../../ui/components/glass_container.dart';
import '../library/services/file_import_service.dart';
import '../library/data/song_repository.dart';
import '../player/services/audio_player_service.dart';
import '../player/services/queue_service.dart';
import '../playlists/components/add_to_playlist_sheet.dart';
import '../settings/settings_screen.dart';
import 'tabs/playlists_tab.dart';
import 'tabs/artists_tab.dart';
import 'tabs/favorites_tab.dart';
import 'providers/library_providers.dart';

// Provider for songs list
final songsProvider = FutureProvider<List<Song>>((ref) async {
  final repository = ref.watch(songRepositoryProvider);
  return await repository.getAllSongs();
});

// Provider for view mode
// Provider for view mode
class GridViewNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void toggle() {
    state = !state;
  }
}

final isGridViewProvider = NotifierProvider<GridViewNotifier, bool>(
  GridViewNotifier.new,
);

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  // int _selectedSegment = 0; // Removed local state

  void _showImportOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add Music'),
        message: const Text('Choose how to add music to your library'),
        actions: [
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.folder, size: 20),
                SizedBox(width: 8),
                Text('Import from Files'),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _importFiles();
            },
          ),
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.arrow_clockwise, size: 20),
                SizedBox(width: 8),
                Text('Scan Music Folder'),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _scanMusicFolder();
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

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

  Future<void> _scanMusicFolder() async {
    try {
      final importService = ref.read(fileImportServiceProvider);

      // Show loading indicator
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CupertinoActivityIndicator(color: Colors.white, radius: 16),
        ),
      );

      final songs = await importService.scanMusicDirectory();

      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss loading

      if (songs.isEmpty) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Scan Complete'),
            content: const Text('No new music files found in the folder.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
        return;
      }

      // Refresh the songs list
      ref.invalidate(songsProvider);

      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Scan Complete'),
          content: Text('Found and imported ${songs.length} new song(s)'),
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
      Navigator.of(context).pop(); // Dismiss loading if shown
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Scan Failed'),
          content: Text('An error occurred: $e'),
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
    final selectedSegment = ref.watch(libraryTabProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            isGridView
                ? CupertinoIcons.list_bullet
                : CupertinoIcons.square_grid_2x2,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          onPressed: () {
            ref.read(isGridViewProvider.notifier).toggle();
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showImportOptions,
              child: const Icon(
                CupertinoIcons.arrow_down_doc,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.gear_alt,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).push(
                  CupertinoPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      child: _buildTabContent(selectedSegment),
    );
  }

  Widget _buildTabContent(int selectedSegment) {
    switch (selectedSegment) {
      case 0:
        return const _SongsTab();
      case 1:
        return const PlaylistsTab();
      case 2:
        return const ArtistsTab();
      case 3:
        return const FavoritesTab();
      default:
        return const _SongsTab();
    }
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

        // Get safe area padding to account for navigation bar
        final topPadding =
            MediaQuery.of(context).padding.top +
            kMinInteractiveDimensionCupertino;

        if (isGridView) {
          return GridView.builder(
            padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 120),
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
          padding: EdgeInsets.only(
            top: topPadding + 8,
            bottom: 120,
          ), // Space for nav bar and bottom nav
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
