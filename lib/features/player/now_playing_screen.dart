import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models/lyrics.dart';
import '../../core/theme/app_theme.dart';
import '../lyrics/services/lyrics_service.dart';
import '../lyrics/lyrics_editor_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioPlayerServiceProvider);
    final currentSong = playerState.currentSong;
    final hasNext = ref.watch(hasNextSongProvider);
    final hasPrevious = ref.watch(hasPreviousSongProvider);
    final lyricsAsync = ref.watch(currentSongLyricsProvider);

    if (currentSong == null) {
      // Shouldn't happen, but handle gracefully
      Navigator.of(context).pop();
      return const SizedBox.shrink();
    }

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(
                      CupertinoIcons.chevron_down,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Now Playing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(
                          CupertinoIcons.pencil,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () async {
                          // Navigate to Editor
                          // if (currentSong == null) return; // Removed redundant check

                          final lyrics =
                              lyricsAsync.value; // Get current loaded lyrics

                          await Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => LyricsEditorScreen(
                                song: currentSong,
                                initialLyrics: lyrics,
                              ),
                            ),
                          );

                          // Refresh lyrics after edit
                          ref.invalidate(currentSongLyricsProvider);
                        },
                      ),
                      const SizedBox(width: 8),
                      // Lyrics Toggle Button
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Icon(
                          CupertinoIcons.text_quote,
                          color: _showLyrics
                              ? AppTheme.primaryColor
                              : Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _showLyrics = !_showLyrics;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Content Area (Artwork or Lyrics)
            Expanded(
              flex: 10,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showLyrics
                    ? lyricsAsync.when(
                        data: (lyrics) {
                          if (lyrics == null) {
                            return const Center(
                              child: Text(
                                'No lyrics found',
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
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: currentSong.artworkPath != null
                                ? Image.asset(
                                    currentSong.artworkPath!,
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

            const SizedBox(height: 40),

            // Song Info (Hidden if Lyrics shown? Maybe kept for context)
            if (!_showLyrics)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      currentSong.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentSong.artists.isNotEmpty
                          ? currentSong.artists.join(', ')
                          : 'Unknown Artist',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (currentSong.album != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        currentSong.album!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Progress Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  CupertinoSlider(
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
                    activeColor: AppTheme.primaryColor,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(playerState.position),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _formatDuration(playerState.duration),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Playback Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Previous button
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
                      size: 36,
                      color: hasPrevious
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),

                  // Play/Pause button
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor,
                    ),
                    child: CupertinoButton(
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
                        size: 36,
                      ),
                    ),
                  ),

                  // Next button
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
                      size: 36,
                      color: hasNext
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _defaultArtwork() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.music_note_2,
          color: AppTheme.primaryColor,
          size: 120,
        ),
      ),
    );
  }
}
