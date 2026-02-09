import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/song_repository.dart';
import '../services/file_import_service.dart';
import '../services/library_scanner_service.dart';
import '../../../core/data/models/song.dart';

// Provider for the currently selected tab in Library (0: Songs, 1: Playlists, 2: Artists)
class LibraryTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int value) {
    state = value;
  }
}

final libraryTabProvider = NotifierProvider<LibraryTabNotifier, int>(
  LibraryTabNotifier.new,
);

// Provider for songs list
final songsProvider = FutureProvider<List<Song>>((ref) async {
  final repository = ref.watch(songRepositoryProvider);
  return await repository.getAllSongs();
});

// Provider for view mode
class GridViewNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void toggle() {
    state = !state;
  }
}

final isGridViewProvider = NotifierProvider<GridViewNotifier, bool>(
  GridViewNotifier.new,
);

final libraryScannerServiceProvider = Provider<LibraryScannerService>((ref) {
  return LibraryScannerService(
    songRepository: ref.watch(songRepositoryProvider),
    metadataService: ref.watch(metadataServiceProvider),
  );
});
