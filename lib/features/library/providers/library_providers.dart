import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the currently selected tab in Library (0: Songs, 1: Playlists, 2: Artists)
final libraryTabProvider = StateProvider<int>((ref) => 0);
