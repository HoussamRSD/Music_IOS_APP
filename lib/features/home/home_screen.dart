import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../library/data/song_repository.dart';
import '../../core/data/models/song.dart';
import '../player/now_playing_screen.dart';
import '../player/services/audio_player_service.dart';

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
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Listen Now'),
            backgroundColor: Color(0xCC1C1C1E),
            border: null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10, left: 20),
              child: Text(
                _getGreeting(),
                style: AppTheme.textTheme.displayMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),

          // Handle different states
          libraryState.when(
            data: (songs) {
              if (songs.isEmpty) {
                return _buildEmptyState();
              }

              final recentSongs = songs.take(5).toList();
              final madeForYou = songs.skip(5).take(5).toList();
              final trending = songs.skip(10).take(5).toList();

              return SliverList(
                delegate: SliverChildListDelegate([
                  if (recentSongs.isNotEmpty) ...[
                    _SectionHeader(title: 'Recently Played'),
                    _HorizontalCardList(songs: recentSongs),
                  ],
                  if (madeForYou.isNotEmpty) ...[
                    const _SectionHeader(title: 'Made for You'),
                    _HorizontalCardList(songs: madeForYou, isLarge: true),
                  ],
                  if (trending.isNotEmpty) ...[
                    const _SectionHeader(title: 'Trending Now'),
                    _HorizontalCardList(songs: trending),
                  ],
                  const SizedBox(height: 100),
                ]),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(child: CupertinoActivityIndicator(radius: 20)),
              ),
            ),
            error: (error, stack) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error loading songs: $error',
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.music_note_list,
              size: 80,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 20),
            Text('No Music Yet', style: AppTheme.textTheme.titleLarge),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Go to Library and tap the + button to import your music files',
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
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

class _HorizontalCardList extends StatelessWidget {
  final List<Song> songs;
  final bool isLarge;

  const _HorizontalCardList({required this.songs, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isLarge ? 280 : 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return Padding(
            padding: const EdgeInsets.only(right: 15),
            child: _AlbumCard(song: song, isLarge: isLarge),
          );
        },
      ),
    );
  }
}

class _AlbumCard extends ConsumerWidget {
  final Song song;
  final bool isLarge;

  const _AlbumCard({required this.song, required this.isLarge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppTheme.surfaceHighlight,
              borderRadius: BorderRadius.circular(isLarge ? 12 : 8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
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
    );
  }
}
