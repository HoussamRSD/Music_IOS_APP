import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models/song.dart';

class QueueState {
  final List<Song> queue;
  final int currentIndex;

  const QueueState({this.queue = const [], this.currentIndex = 0});

  Song? get currentSong => queue.isEmpty ? null : queue[currentIndex];
  bool get hasNext => currentIndex < queue.length - 1;
  bool get hasPrevious => currentIndex > 0;

  QueueState copyWith({List<Song>? queue, int? currentIndex}) {
    return QueueState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class QueueController extends Notifier<QueueState> {
  @override
  QueueState build() {
    return const QueueState();
  }

  void setQueue(List<Song> songs, {int startIndex = 0}) {
    state = QueueState(queue: songs, currentIndex: startIndex);
  }

  void addToQueue(Song song) {
    state = state.copyWith(queue: [...state.queue, song]);
  }

  void next() {
    if (state.hasNext) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
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
