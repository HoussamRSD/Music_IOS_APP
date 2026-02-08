import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/song_repository.dart';
import '../services/file_import_service.dart';
import '../services/library_scanner_service.dart';

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

final libraryScannerServiceProvider = Provider<LibraryScannerService>((ref) {
  return LibraryScannerService(
    songRepository: ref.watch(songRepositoryProvider),
    metadataService: ref.watch(metadataServiceProvider),
  );
});
