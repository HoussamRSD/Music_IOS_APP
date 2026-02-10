import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../ui/components/glass_container.dart';
import '../library/data/song_repository.dart';
import '../library/services/file_import_service.dart';
import '../../core/data/models/song.dart';
import '../player/now_playing_screen.dart';
import '../player/services/audio_player_service.dart';
import '../settings/settings_screen.dart';
import '../navigation/models/navigation_tab.dart';
import '../navigation/providers/navigation_provider.dart';
import '../library/providers/library_providers.dart';
import '../settings/providers/font_provider.dart';

import '../library/services/library_scanner_service.dart';

final homeSongsProvider = FutureProvider<List<Song>>((ref) async {
  final repository = ref.watch(songRepositoryProvider);
  return await repository.getAllSongs();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(homeSongsProvider);
    final appTextStyles = ref.watch(appTextStylesProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        middle: Text('Home', style: appTextStyles.titleMedium()),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showImportOptions(context, ref),
              child: const Icon(
                CupertinoIcons.arrow_down_doc,
                color: AppTheme.primaryColor,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _scanMusicFolder(context, ref),
              child: const Icon(
                CupertinoIcons.arrow_clockwise,
                color: AppTheme.primaryColor,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.gear_alt,
                color: AppTheme.primaryColor,
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
      child: CustomScrollView(
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.only(top: 100),
          ), // Added top padding
          // Greeting & Navigation Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: appTextStyles
                        .displayMedium(color: AppTheme.textSecondary)
                        .copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  _NavigationGrid(),
                ],
              ),
            ),
          ),

          libraryState.when(
            data: (songs) {
              if (songs.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context, ref, appTextStyles),
                );
              }

              final recentSongs = songs.take(5).toList();

              return SliverList(
                delegate: SliverChildListDelegate([
                  if (recentSongs.isNotEmpty) ...[
                    _SectionHeader(title: 'Recently Played'),
                    _HorizontalCardList(songs: recentSongs),
                  ],

                  // Removed Trending Now as requested
                  const SizedBox(height: 180),
                ]),
              );
            },
            loading: () => const SliverFillRemaining(
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
    );
  }

  void _navigateToTab(BuildContext context, WidgetRef ref, NavigationTab tab) {
    if (tab == NavigationTab.home) return;

    final settings = ref.read(navigationProvider);
    final isVisible = !settings.hidden.contains(tab);

    if (isVisible) {
      // Tab is visible in bottom bar, switch to it using GoRouter
      final shell = context
          .findAncestorStateOfType<StatefulNavigationShellState>();
      if (shell != null && tab.branchIndex != null) {
        // Switch branch
        shell.goBranch(
          tab.branchIndex!,
          initialLocation:
              tab.branchIndex ==
              shell.currentIndex, // Reset stack if same branch
        );

        // If it's a library tab, set the sub-tab index
        if (tab.libraryTabIndex != null) {
          ref.read(libraryTabProvider.notifier).setTab(tab.libraryTabIndex!);
        }
      }
    } else {
      // Tab is hidden, open as new page
      // We need to determine imports for specific screens if they are not exported by library_screen
      // However, we can use the specific tab widgets directly if they are public
      // Or map them here. Since we refactored SongsTab, we can import it.
      // We need imports for other tabs too.
      // Let's defer actual navigation to a helper or just push the route here.
      // Ideally we should use GoRouter push, but for now simple push is fine or context.push

      // Since existing tabs are part of library, we might want to push a specific route
      // But LibraryScreen handles tabs internally.
      // If we want a standalone page for "Songs" when it's hidden, we need to wrap SongsTab in a Scaffold.

      Widget page;
      String title = tab.label;

      // Lazy import resolution by using a builder or separate file would be cleaner,
      // but for now let's use a simple switch if we have access to the classes.
      // We need to import the tab classes.

      // See imports added at top... we need to add imports for PlaylistsTab etc if they are used here.
      // Or better, trigger navigation to a route that we define in app_router.dart for standalone views?
      // For now, let's just use the Library tab logic but forcing the tab index if we navigate to library...
      // BUT if it's hidden, we can't navigate to the library branch's tab bar item easily without showing it?
      // Actually, if it's hidden from the BAR, it doesn't mean the route doesn't exist.
      // But if we want to show it *without* the bottom bar highlight or just as a page:

      // Let's implement a simple "Push new page with this tab content" strategy.

      // We need to import the tab widgets in the HomeScreen file for this to work.
      // I will add necessary imports in the next step or this one if I can.

      // For now, basic stubbing or using what we have.
      // Since we don't have imports for PlaylistsTab etc in this replacement content yet (I need to check imports in original vs replacement),
      // I added generic imports but I should ensure they are correct.

      // Actually, navigation via Router is best.
      // context.push('/library?tab=${tab.libraryTabIndex}'); // If we supported query params for tab

      // Let's assume for now we use the same logic: go to library branch and set tab.
      // If the tab is "hidden" from the bottom bar, it might still be accessible via the router branch 1 (Library).
      // The "hidden" attribute in NavigationSettings only controls the *Bottom Bar Item* visibility.
      // The branch itself (Library) is likely still legally accessible.
      // So we can just switch to Library branch and set the libraryTabProvider!

      final shell = context
          .findAncestorStateOfType<StatefulNavigationShellState>();
      if (shell != null) {
        // Switch to library branch (index 1) which is always there
        shell.goBranch(1);
        if (tab.libraryTabIndex != null) {
          ref.read(libraryTabProvider.notifier).setTab(tab.libraryTabIndex!);
        }
      }
    }
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    AppTextStyles appTextStyles,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.music_albums_fill,
            size: 60,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 20),
        Text('Welcome to DOPLIN', style: appTextStyles.displayMedium()),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Your library is looking a bit empty. Import your music tracks to get started.',
            textAlign: TextAlign.center,
            style: appTextStyles.bodyMedium(color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 30),
        CupertinoButton.filled(
          onPressed: () => _importFiles(context, ref),
          child: const Text('Import Music Files'),
        ),
        const SizedBox(height: 10),
        Text(
          'Supports MP3, FLAC, M4A, WAV',
          style: appTextStyles
              .bodySmall(color: AppTheme.textSecondary.withOpacity(0.5))
              .copyWith(fontSize: 12),
        ),
      ],
    );
  }

  void _showImportOptions(BuildContext context, WidgetRef ref) {
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
              _importFiles(context, ref);
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
              _scanMusicFolder(context, ref);
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

  Future<void> _scanMusicFolder(BuildContext context, WidgetRef ref) async {
    try {
      final scannerService = ref.read(libraryScannerServiceProvider);

      // Show loading indicator
      if (!context.mounted) return;
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: CupertinoAlertDialog(
            title: const Text('Scanning Library'),
            content: const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoActivityIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'Please wait...',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        final result = await scannerService.scanLibrary(forceRescan: true);

        if (!context.mounted) return;

        // Dismiss loading dialog
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        // Refresh the songs list and invalidate related providers
        ref.invalidate(homeSongsProvider);
        // Force refresh of metadata/artwork cache
        ref.invalidate(fileImportServiceProvider);

        if (!context.mounted) return;

        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Rescan Complete'),
            content: Text(
              'Added: ${result.added}\nUpdated: ${result.updated}\nRemoved: ${result.removed}',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      } catch (e) {
        if (!context.mounted) return;

        // Dismiss loading dialog if still open
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        if (!context.mounted) return;

        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Scan Failed'),
            content: Text('An error occurred during scan: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      // Try to dismiss any open dialog
      try {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      } catch (_) {}

      if (!context.mounted) return;

      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('An unexpected error occurred: $e'),
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

  Future<void> _importFiles(BuildContext context, WidgetRef ref) async {
    try {
      final importService = ref.read(fileImportServiceProvider);
      final songs = await importService.importFiles();

      if (songs.isNotEmpty) {
        ref.invalidate(homeSongsProvider);
        if (context.mounted) {
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Import Successful'),
              content: Text('Imported ${songs.length} tracks.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Import Failed'),
            content: Text('Error: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class _NavigationGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 20) / 2;
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            _NavigationCard(
              title: 'Songs',
              icon: CupertinoIcons.music_note,
              color: Colors.blueAccent,
              width: itemWidth,
              onTap: () => HomeScreen()._navigateToTab(
                context,
                ref,
                NavigationTab.songs,
              ),
            ),
            _NavigationCard(
              title: 'Favorites',
              icon: CupertinoIcons.heart_fill,
              color: Colors.pinkAccent,
              width: itemWidth,
              onTap: () => HomeScreen()._navigateToTab(
                context,
                ref,
                NavigationTab.favorites,
              ),
            ),
            _NavigationCard(
              title: 'Playlists',
              icon: CupertinoIcons.music_note_list,
              color: Colors.purpleAccent,
              width: itemWidth,
              onTap: () => HomeScreen()._navigateToTab(
                context,
                ref,
                NavigationTab.playlists,
              ),
            ),
            _NavigationCard(
              title: 'Artists',
              icon: CupertinoIcons.person_2_fill,
              color: Colors.orangeAccent,
              width: itemWidth,
              onTap: () => HomeScreen()._navigateToTab(
                context,
                ref,
                NavigationTab.artists,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NavigationCard extends ConsumerWidget {
  final String title;
  final IconData icon;
  final Color color;
  final double width;
  final VoidCallback onTap;

  const _NavigationCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTextStyles = ref.watch(appTextStylesProvider);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: 80,
        child: GlassContainer(
          borderRadius: BorderRadius.circular(16),
          opacity: 0.1,
          blur: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(title, style: appTextStyles.titleMedium()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends ConsumerWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTextStyles = ref.watch(appTextStylesProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: appTextStyles.titleLarge()),
          const Icon(
            CupertinoIcons.chevron_right,
            color: AppTheme.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _HorizontalCardList extends ConsumerWidget {
  final List<Song> songs;

  const _HorizontalCardList({required this.songs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTextStyles = ref.watch(appTextStylesProvider);
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          final size = 160.0;

          return GestureDetector(
            onTap: () {
              ref.read(audioPlayerServiceProvider.notifier).playSong(song);
              Navigator.of(context, rootNavigator: true).push(
                CupertinoPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => const NowPlayingScreen(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassContainer(
                    borderRadius: BorderRadius.circular(8),
                    opacity: 0.1,
                    blur: 10,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        image: song.artworkPath != null
                            ? DecorationImage(
                                image: FileImage(File(song.artworkPath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: song.artworkPath == null
                          ? Icon(
                              CupertinoIcons.music_note,
                              color: AppTheme.textSecondary,
                              size: size / 3,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: size,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: appTextStyles.bodyMedium(
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song.artists.join(', '),
                          style: appTextStyles.bodyMedium(
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
