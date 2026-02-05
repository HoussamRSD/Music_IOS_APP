import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/data/models/song.dart';

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

class AudioPlayerService extends StateNotifier<PlayerState> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  AudioPlayerService() : super(const PlayerState()) {
    _init();
  }

  void _init() {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((playerState) {
      state = state.copyWith(
        isPlaying: playerState.playing,
        isLoading:
            playerState.processingState == ProcessingState.loading ||
            playerState.processingState == ProcessingState.buffering,
      );
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });
  }

  Future<void> playSong(Song song) async {
    try {
      state = state.copyWith(currentSong: song, isLoading: true);

      await _audioPlayer.setFilePath(song.filePath);
      await _audioPlayer.play();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> play() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    state = const PlayerState();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

// Riverpod Providers
final audioPlayerServiceProvider =
    StateNotifierProvider<AudioPlayerService, PlayerState>((ref) {
      return AudioPlayerService();
    });

// Convenience provider for current playing state
final isPlayingProvider = Provider<bool>((ref) {
  return ref.watch(audioPlayerServiceProvider).isPlaying;
});

// Convenience provider for current song
final currentSongProvider = Provider<Song?>((ref) {
  return ref.watch(audioPlayerServiceProvider).currentSong;
});
