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
    final songs = libraryState.asData?.value ?? [];

    // Mock data for "Made For You" and "Trending"
    final recentSongs = songs.take(5).toList();
    final madeForYou = songs.skip(5).take(5).toList();
    final trending = songs.skip(10).take(5).toList();

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Listen Now'),
            backgroundColor: Color(0xCC1C1C1E), // Translucent
            border: null, // No border for cleaner look
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

          // Recently Played Carousel
          if (recentSongs.isNotEmpty) ...[
            _buildSectionHeader('Recently Played'),
            SliverToBoxAdapter(child: _HorizontalCardList(songs: recentSongs)),
          ],

          // Made For You Carousel
          if (madeForYou.isNotEmpty) ...[
            _buildSectionHeader('Made for You'),
            SliverToBoxAdapter(
              child: _HorizontalCardList(songs: madeForYou, isLarge: true),
            ),
          ],

          // Trending Carousel
          if (trending.isNotEmpty) ...[
            _buildSectionHeader('Trending Now'),
            SliverToBoxAdapter(child: _HorizontalCardList(songs: trending)),
          ],

          // Bottom Padding for MiniPlayer
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTheme.textTheme.titleLarge),
            Icon(
              CupertinoIcons.chevron_right,
              color: AppTheme.textSecondary,
              size: 20,
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
        // Open Now Playing
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
          // Artwork
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

          // Texts
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
