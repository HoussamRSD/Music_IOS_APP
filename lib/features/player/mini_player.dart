import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/components/glass_container.dart';
import 'now_playing_screen.dart';
import '../player/services/audio_player_service.dart';
import '../player/services/queue_service.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerServiceProvider);
    final currentSong = playerState.currentSong;

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          CupertinoPageRoute(
            fullscreenDialog: true,
            builder: (context) => const NowPlayingScreen(),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF2C2C2E), // Darker glass
          opacity: 0.8,
          blur: 20,
          child: Container(
            height: 60,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Artwork
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.surfaceHighlight,
                    image: currentSong.artworkPath != null
                        ? DecorationImage(
                            image: FileImage(File(currentSong.artworkPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: currentSong.artworkPath == null
                      ? Icon(
                          CupertinoIcons.music_note,
                          color: AppTheme.textSecondary,
                          size: 20,
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentSong.title,
                        style: AppTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        currentSong.artists.join(', '),
                        style: AppTheme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(
                        playerState.isPlaying
                            ? CupertinoIcons.pause_fill
                            : CupertinoIcons.play_fill,
                        color: AppTheme.textPrimary,
                        size: 24,
                      ),
                      onPressed: () {
                        ref
                            .read(audioPlayerServiceProvider.notifier)
                            .togglePlayPause();
                      },
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(
                        CupertinoIcons.forward_fill,
                        color: AppTheme.textPrimary,
                        size: 24,
                      ),
                      onPressed: () {
                        // Use Queue Controller for navigation
                        ref.read(queueControllerProvider.notifier).next();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
