import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models/song.dart';
import 'package:flutter/foundation.dart';
import '../../lyrics/services/lyrics_service.dart';
import 'audio_handler.dart';

class PlayerState {
  final Song? currentSong;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool isLoading;

  const PlayerState({
    this.currentSong,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isLoading = false,
  });

  PlayerState copyWith({
    Song? currentSong,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    bool? isLoading,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AudioPlayerController extends Notifier<PlayerState> {
  MyAudioHandler? _audioHandler;

  @override
  PlayerState build() {
    _initAudioService();
    return const PlayerState();
  }

  Future<void> _initAudioService() async {
    try {
      _audioHandler = await AudioService.init(
        builder: () => MyAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.doplin.channel.audio',
          androidNotificationChannelName: 'DOPLIN',
          androidNotificationOngoing: true,
        ),
      );

      // Listen to playback state
      _audioHandler?.playbackState.listen((playbackState) {
        state = state.copyWith(
          isPlaying: playbackState.playing,
          position: playbackState.position,
          isLoading:
              playbackState.processingState == AudioProcessingState.loading ||
              playbackState.processingState == AudioProcessingState.buffering,
        );
      });

      // Listen to media item changes
      _audioHandler?.mediaItem.listen((item) {
        if (item?.duration != null) {
          state = state.copyWith(duration: item!.duration);
        }
      });
    } catch (e) {
      // audio_service may not be fully supported on all platforms
      // Fall back to basic just_audio without background support
    }
  }

  Future<void> playSong(Song song) async {
    try {
      state = state.copyWith(currentSong: song, isLoading: true);

      // Pre-fetch lyrics to cache them before file is locked by player (Fix for Windows)
      // We don't await this to avoid delaying playback start significantly,
      // but we start it before the handler locks the file.
      // Actually, we SHOULD await it if we want to guarantee cache hit,
      // but waiting might delay UI. However, getLyrics checks DB first (fast).
      // If DB miss, it reads file. Reading file takes ~10-50ms.
      // So awaiting is safe and ensures cache is populated.
      try {
        debugPrint(
          'AudioPlayerService: Pre-fetching lyrics (local only) for ${song.title}',
        );
        // Only fetch local/embedded lyrics to avoid network delay
        final l = await ref
            .read(lyricsServiceProvider)
            .getLyrics(song, searchOnline: false);
        debugPrint(
          'AudioPlayerService: Local pre-fetch result: ${l != null ? "Found" : "Not Found"}',
        );

        // Trigger background online search if not found locally
        if (l == null) {
          debugPrint('AudioPlayerService: Triggering background online search');
          ref
              .read(lyricsServiceProvider)
              .getLyrics(song, searchOnline: true)
              .ignore();
        }
      } catch (e) {
        debugPrint('AudioPlayerService: Pre-fetch error: $e');
      }

      if (_audioHandler != null) {
        await _audioHandler!.playSong(song);
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> playYouTubeVideo(
    String url,
    String title,
    String author,
    String artworkUrl,
  ) async {
    try {
      state = state.copyWith(isLoading: true);
      // Create a temporary Song object for UI (optional, or just update state)
      // For now, we rely on mediaItem updates from handler, but handler needs the item first.

      if (_audioHandler != null) {
        final item = MediaItem(
          id: url,
          title: title,
          artist: author,
          artUri: Uri.parse(artworkUrl),
        );
        await _audioHandler!.playFromUrl(url, item);
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> play() async {
    await _audioHandler?.play();
  }

  Future<void> pause() async {
    await _audioHandler?.pause();
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioHandler?.seek(position);
  }

  Future<void> stop() async {
    await _audioHandler?.stop();
    state = const PlayerState();
  }
}

// Riverpod Providers
final audioPlayerServiceProvider =
    NotifierProvider<AudioPlayerController, PlayerState>(() {
      return AudioPlayerController();
    });

// Convenience provider for current playing state
final isPlayingProvider = Provider<bool>((ref) {
  return ref.watch(audioPlayerServiceProvider).isPlaying;
});

// Convenience provider for current song
final currentSongProvider = Provider<Song?>((ref) {
  return ref.watch(audioPlayerServiceProvider).currentSong;
});
