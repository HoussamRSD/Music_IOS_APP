import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models/song.dart';

enum RepeatMode { off, all, one }

class QueueState {
  final List<Song> queue;
  final List<Song> originalQueue; // For shuffle restore
  final int currentIndex;
  final bool shuffleEnabled;
  final RepeatMode repeatMode;

  const QueueState({
    this.queue = const [],
    this.originalQueue = const [],
    this.currentIndex = 0,
    this.shuffleEnabled = false,
    this.repeatMode = RepeatMode.off,
  });

  Song? get currentSong => queue.isEmpty ? null : queue[currentIndex];
  bool get hasNext =>
      repeatMode != RepeatMode.off || currentIndex < queue.length - 1;
  bool get hasPrevious => currentIndex > 0;

  QueueState copyWith({
    List<Song>? queue,
    List<Song>? originalQueue,
    int? currentIndex,
    bool? shuffleEnabled,
    RepeatMode? repeatMode,
  }) {
    return QueueState(
      queue: queue ?? this.queue,
      originalQueue: originalQueue ?? this.originalQueue,
      currentIndex: currentIndex ?? this.currentIndex,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }
}

class QueueController extends Notifier<QueueState> {
  @override
  QueueState build() {
    return const QueueState();
  }

  void setQueue(List<Song> songs, {int startIndex = 0}) {
    state = QueueState(
      queue: songs,
      originalQueue: songs,
      currentIndex: startIndex,
      shuffleEnabled: state.shuffleEnabled,
      repeatMode: state.repeatMode,
    );
  }

  void addToQueue(Song song) {
    state = state.copyWith(
      queue: [...state.queue, song],
      originalQueue: [...state.originalQueue, song],
    );
  }

  void next() {
    if (state.repeatMode == RepeatMode.one) {
      // Repeat current song - index stays same, caller should replay
      return;
    }

    if (state.currentIndex < state.queue.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    } else if (state.repeatMode == RepeatMode.all) {
      // Loop back to start
      state = state.copyWith(currentIndex: 0);
    }
  }

  void previous() {
    if (state.hasPrevious) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  void jumpTo(int index) {
    if (index >= 0 && index < state.queue.length) {
      state = state.copyWith(currentIndex: index);
    }
  }

  void toggleShuffle() {
    if (state.shuffleEnabled) {
      // Turn off shuffle - restore original order
      final currentSong = state.currentSong;
      final newIndex = currentSong != null
          ? state.originalQueue.indexWhere((s) => s.id == currentSong.id)
          : 0;
      state = state.copyWith(
        queue: List.from(state.originalQueue),
        currentIndex: newIndex >= 0 ? newIndex : 0,
        shuffleEnabled: false,
      );
    } else {
      // Turn on shuffle
      final currentSong = state.currentSong;
      final shuffled = List<Song>.from(state.queue);
      shuffled.shuffle();

      // Move current song to front if exists
      if (currentSong != null) {
        shuffled.removeWhere((s) => s.id == currentSong.id);
        shuffled.insert(0, currentSong);
      }

      state = state.copyWith(
        queue: shuffled,
        currentIndex: 0,
        shuffleEnabled: true,
      );
    }
  }

  void cycleRepeatMode() {
    final modes = RepeatMode.values;
    final nextIndex = (state.repeatMode.index + 1) % modes.length;
    state = state.copyWith(repeatMode: modes[nextIndex]);
  }

  void clear() {
    state = const QueueState();
  }
}

// Providers
final queueControllerProvider = NotifierProvider<QueueController, QueueState>(
  () {
    return QueueController();
  },
);

final currentQueueSongProvider = Provider<Song?>((ref) {
  return ref.watch(queueControllerProvider).currentSong;
});

final hasNextSongProvider = Provider<bool>((ref) {
  return ref.watch(queueControllerProvider).hasNext;
});

final hasPreviousSongProvider = Provider<bool>((ref) {
  return ref.watch(queueControllerProvider).hasPrevious;
});

final shuffleEnabledProvider = Provider<bool>((ref) {
  return ref.watch(queueControllerProvider).shuffleEnabled;
});

final repeatModeProvider = Provider<RepeatMode>((ref) {
  return ref.watch(queueControllerProvider).repeatMode;
});
