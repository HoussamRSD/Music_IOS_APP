import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/data/models/song.dart';

class MyAudioHandler extends BaseAudioHandler {
  final AudioPlayer _audioPlayer = AudioPlayer();

  MyAudioHandler() {
    // Listen to player state and broadcast to audio_service
    _audioPlayer.playerStateStream.listen((playerState) {
      final playing = playerState.playing;
      final processingState = _mapProcessingState(playerState.processingState);

      playbackState.add(
        playbackState.value.copyWith(
          playing: playing,
          processingState: processingState,
          controls: [
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
        ),
      );
    });

    // Listen to position
    _audioPlayer.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    });

    // Listen to duration
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        mediaItem.add(mediaItem.value?.copyWith(duration: duration));
      }
    });
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  Future<void> playSong(Song song) async {
    // Create MediaItem for lock screen
    final item = MediaItem(
      id: song.id?.toString() ?? song.filePath,
      album: song.album,
      title: song.title,
      artist: song.artists.isNotEmpty
          ? song.artists.join(', ')
          : 'Unknown Artist',
      duration: song.duration != null
          ? Duration(milliseconds: song.duration!)
          : null,
      artUri: song.artworkPath != null ? Uri.file(song.artworkPath!) : null,
    );

    mediaItem.add(item);

    await _audioPlayer.setFilePath(song.filePath);
    await play();
  }

  Future<void> playFromUrl(String url, MediaItem item) async {
    mediaItem.add(item);
    await _audioPlayer.setUrl(url);
    await play();
  }

  @override
  Future<void> play() => _audioPlayer.play();

  @override
  Future<void> pause() => _audioPlayer.pause();

  @override
  Future<void> seek(Duration position) => _audioPlayer.seek(position);

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    // This will be called from the queue service
    // For now, just a placeholder
  }

  @override
  Future<void> skipToPrevious() async {
    // This will be called from the queue service
    // For now, just a placeholder
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
