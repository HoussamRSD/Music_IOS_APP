import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../ui/components/glass_container.dart';
import '../library/data/song_repository.dart';
import '../library/services/file_import_service.dart';
import '../../core/data/models/song.dart';
import '../player/now_playing_screen.dart';
import '../player/services/audio_player_service.dart';
import '../settings/settings_screen.dart';

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
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Listen Now'),
            backgroundColor: const Color(0xCC1C1C1E),
            border: null,
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Text(
                _getGreeting(),
                style: AppTheme.textTheme.displayMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
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
              final trending = songs.take(10).toList().reversed.toList();

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

                  if (trending.isNotEmpty) ...[
                    _SectionHeader(title: 'Trending Now'),
                    _HorizontalCardList(songs: trending),
                  ],

                  // Quick Access to All Songs
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: CupertinoButton(
                      color: AppTheme.surfaceHighlight,
                      child: const Text('View All Songs'),
                      onPressed: () {
                        // Navigate to library tab (index 1)
                        // This requires GoRouter shell navigation, but for now we can rely on the tab bar
                      },
                    ),
                  ),

                  const SizedBox(height: 120),
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
