import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models/lyrics.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_text_styles.dart';
import '../library/data/song_repository.dart';
import '../library/library_screen.dart';
import '../lyrics/services/lyrics_service.dart';
import '../lyrics/lyrics_editor_screen.dart';
import '../playlists/components/add_to_playlist_sheet.dart';
import '../settings/providers/font_provider.dart';
import 'components/lyrics_view.dart';
import 'services/audio_player_service.dart';
import 'services/queue_service.dart';

// Provider to fetch lyrics for the current song
final currentSongLyricsProvider = FutureProvider<Lyrics?>((ref) async {
  final currentSong = ref.watch(currentSongProvider);
  if (currentSong == null) return null;
  return ref.watch(lyricsServiceProvider).getLyrics(currentSong);
});

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  bool _showLyrics = false;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatRemainingTime(Duration position, Duration total) {
    final remaining = total - position;
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds.remainder(60);
    return '-$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioPlayerServiceProvider);
    final currentSong = playerState.currentSong;
    final hasNext = ref.watch(hasNextSongProvider);
    final hasPrevious = ref.watch(hasPreviousSongProvider);
    final shuffleEnabled = ref.watch(shuffleEnabledProvider);
    final repeatMode = ref.watch(repeatModeProvider);
    final lyricsAsync = ref.watch(currentSongLyricsProvider);
    final selectedFont = ref.watch(fontProvider).fontFamily;

    if (currentSong == null) {
      Navigator.of(context).pop();
      return const SizedBox.shrink();
    }

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header - minimal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Artwork
            Expanded(
              flex: 5,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showLyrics
                    ? lyricsAsync.when(
                        data: (lyrics) {
                          if (lyrics == null) {
                            return const Center(
                              child: Text(
                                'No lyrics available',
                                style: TextStyle(color: Colors.white54),
                              ),
                            );
                          }
                          return LyricsView(
                            lyrics: lyrics,
                            position: playerState.position,
                            onSeek: (position) {
                              ref
                                  .read(audioPlayerServiceProvider.notifier)
                                  .seek(position);
                            },
                          );
                        },
                        loading: () => const Center(
                          child: CupertinoActivityIndicator(
                            color: Colors.white,
                          ),
                        ),
                        error: (error, stack) => const Center(
                          child: Text(
                            'Error loading lyrics',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: currentSong.artworkPath != null
                                  ? Image.file(
                                      File(currentSong.artworkPath!),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _defaultArtwork(),
                                    )
                                  : _defaultArtwork(),
                            ),
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),

            // Progress Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                      thumbColor: Colors.white,
                      overlayColor: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: playerState.duration.inMilliseconds > 0
                          ? playerState.position.inMilliseconds /
                                playerState.duration.inMilliseconds
                          : 0.0,
                      onChanged: (value) {
                        final position = Duration(
                          milliseconds:
                              (value * playerState.duration.inMilliseconds)
                                  .toInt(),
                        );
                        ref
                            .read(audioPlayerServiceProvider.notifier)
                            .seek(position);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(playerState.position),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatRemainingTime(
                            playerState.position,
                            playerState.duration,
                          ),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Song Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    currentSong.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ).withAppFont(selectedFont),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${currentSong.artists.isNotEmpty ? currentSong.artists.join(', ') : 'Unknown Artist'}${currentSong.album != null ? ' — ${currentSong.album}' : ''}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                    ).withAppFont(selectedFont),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Main Controls: Shuffle | Previous | Play/Pause | Next | Repeat
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Shuffle
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      ref
                          .read(queueControllerProvider.notifier)
                          .toggleShuffle();
                    },
                    child: Icon(
                      CupertinoIcons.shuffle,
                      size: 24,
                      color: shuffleEnabled
                          ? AppTheme.primaryColor
                          : Colors.white.withValues(alpha: 0.8),
                    ),
                  ),

                  // Previous
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: hasPrevious
                        ? () {
                            ref
                                .read(queueControllerProvider.notifier)
                                .previous();
                            final prevSong = ref.read(currentQueueSongProvider);
                            if (prevSong != null) {
                              ref
                                  .read(audioPlayerServiceProvider.notifier)
                                  .playSong(prevSong);
                            }
                          }
                        : null,
                    child: Icon(
                      CupertinoIcons.backward_fill,
                      size: 40,
                      color: hasPrevious
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),

                  // Play/Pause
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      ref
                          .read(audioPlayerServiceProvider.notifier)
                          .togglePlayPause();
                    },
                    child: Icon(
                      playerState.isPlaying
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.play_fill,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),

                  // Next
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: hasNext
                        ? () {
                            ref.read(queueControllerProvider.notifier).next();
                            final nextSong = ref.read(currentQueueSongProvider);
                            if (nextSong != null) {
                              ref
                                  .read(audioPlayerServiceProvider.notifier)
                                  .playSong(nextSong);
                            }
                          }
                        : null,
                    child: Icon(
                      CupertinoIcons.forward_fill,
                      size: 40,
                      color: hasNext
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),

                  // Repeat
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      ref
                          .read(queueControllerProvider.notifier)
                          .cycleRepeatMode();
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.repeat,
                          size: 24,
                          color: repeatMode != RepeatMode.off
                              ? AppTheme.primaryColor
                              : Colors.white.withValues(alpha: 0.8),
                        ),
                        if (repeatMode == RepeatMode.one)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '1',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Secondary Controls: Heart | Speaker | More
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Heart (Favorite)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      await ref
                          .read(songRepositoryProvider)
                          .toggleFavorite(
                            currentSong.id!,
                            !currentSong.isFavorite,
                          );
                      ref.invalidate(songsProvider);
                      // Force refresh of current song state
                      ref.invalidate(currentSongProvider);
                    },
                    child: Icon(
                      currentSong.isFavorite
                          ? CupertinoIcons.heart_fill
                          : CupertinoIcons.heart,
                      size: 24,
                      color: currentSong.isFavorite
                          ? AppTheme.primaryColor
                          : Colors.white.withValues(alpha: 0.8),
                    ),
                  ),

                  // Speaker / AirPlay
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.speaker_2,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Speaker',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // More options
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _showMoreOptions(context, ref, currentSong);
                    },
                    child: Icon(
                      CupertinoIcons.ellipsis_circle_fill,
                      size: 24,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Bottom Bar: Queue | Collapse | Lyrics
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Queue
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _showQueueSheet(context, ref);
                    },
                    child: Icon(
                      CupertinoIcons.list_bullet,
                      size: 24,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),

                  // Collapse
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Icon(
                      CupertinoIcons.chevron_down,
                      size: 28,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),

                  // Lyrics
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _showLyrics = !_showLyrics;
                      });
                    },
                    child: Icon(
                      CupertinoIcons.text_quote,
                      size: 24,
                      color: _showLyrics
                          ? AppTheme.primaryColor
                          : Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(
    BuildContext context,
    WidgetRef ref,
    dynamic currentSong,
  ) {
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
                builder: (context) => AddToPlaylistSheet(song: currentSong),
              );
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Edit Lyrics'),
            onPressed: () async {
              Navigator.pop(context);
              final lyrics = ref.read(currentSongLyricsProvider).value;
              await Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => LyricsEditorScreen(
                    song: currentSong,
                    initialLyrics: lyrics,
                  ),
                ),
              );
              ref.invalidate(currentSongLyricsProvider);
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

  void _showQueueSheet(BuildContext context, WidgetRef ref) {
    final queueState = ref.read(queueControllerProvider);
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Up Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Done'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: queueState.queue.length,
                itemBuilder: (context, index) {
                  final song = queueState.queue[index];
                  final isPlaying = index == queueState.currentIndex;
                  return CupertinoListTile(
                    backgroundColor: isPlaying
                        ? AppTheme.primaryColor.withValues(alpha: 0.2)
                        : Colors.transparent,
                    leading: isPlaying
                        ? const Icon(
                            CupertinoIcons.play_fill,
                            color: AppTheme.primaryColor,
                            size: 16,
                          )
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                    title: Text(
                      song.title,
                      style: TextStyle(
                        color: isPlaying ? AppTheme.primaryColor : Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      song.artists.join(', '),
                      style: const TextStyle(color: Colors.white54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      ref.read(queueControllerProvider.notifier).jumpTo(index);
                      ref
                          .read(audioPlayerServiceProvider.notifier)
                          .playSong(song);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultArtwork() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.music_note_2,
          color: AppTheme.primaryColor,
          size: 100,
        ),
      ),
    );
  }
}
