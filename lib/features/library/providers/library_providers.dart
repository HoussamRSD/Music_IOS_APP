import 'package:flutter_riverpod/flutter_riverpod.dart';

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
