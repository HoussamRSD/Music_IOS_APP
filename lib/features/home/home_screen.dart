import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
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

final homeSongsProvider = FutureProvider<List<Song>>((ref) async {
  final repository = ref.watch(songRepositoryProvider);
  return await repository.getAllSongs();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(homeSongsProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        middle: Text('Home', style: AppTheme.textTheme.titleMedium),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.settings,
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
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.add_circled,
                color: AppTheme.primaryColor,
              ),
              onPressed: () => _importFiles(context, ref),
            ),
          ],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          // Greeting & Navigation Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: AppTheme.textTheme.displayMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
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
                  child: _buildEmptyState(context, ref),
                );
              }

              final recentSongs = songs.take(5).toList();
              final madeForYou = songs.skip(5).take(5).toList();

              return SliverList(
                delegate: SliverChildListDelegate([
                  if (recentSongs.isNotEmpty) ...[
                    _SectionHeader(title: 'Recently Played'),
                    _HorizontalCardList(songs: recentSongs),
                  ],

                  if (madeForYou.isNotEmpty) ...[
                    _SectionHeader(title: 'Made for You'),
                    _HorizontalCardList(songs: madeForYou, isLarge: true),
                  ],

                  // Removed Trending Now as requested

                  // Quick Access to All Songs
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: CupertinoButton(
                      color: AppTheme.surfaceHighlight,
                      child: const Text('View All Songs'),
                      onPressed: () {
                        _navigateToTab(context, ref, NavigationTab.songs);
                      },
                    ),
                  ),

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
              shell
                  .currentIndex, // Reset stack if same branch
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

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
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
        Text('Welcome to DOPLIN', style: AppTheme.textTheme.displayMedium),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Your library is looking a bit empty. Import your music tracks to get started.',
            textAlign: TextAlign.center,
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
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
          style: AppTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
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

class _NavigationCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
              Text(
                title,
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTheme.textTheme.titleLarge),
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
  final bool isLarge;

  const _HorizontalCardList({required this.songs, this.isLarge = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: isLarge ? 280 : 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          final size = isLarge ? 220.0 : 160.0;

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
                    borderRadius: BorderRadius.circular(isLarge ? 12 : 8),
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
                          style: isLarge
                              ? AppTheme.textTheme.bodyLarge
                              : AppTheme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textPrimary,
                                ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song.artists.join(', '),
                          style: AppTheme.textTheme.bodyMedium?.copyWith(
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
