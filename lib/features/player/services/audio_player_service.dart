import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models/song.dart';
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
          androidNotificationChannelId: 'com.glassmusic.channel.audio',
          androidNotificationChannelName: 'Glass Music',
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

      if (_audioHandler != null) {
        await _audioHandler!.playSong(song);
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
