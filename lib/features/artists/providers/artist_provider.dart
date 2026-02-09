import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../library/providers/library_providers.dart';
import '../../../core/data/models/song.dart';

// Provider that returns a sorted list of all unique artist names
final allArtistsProvider = Provider<List<String>>((ref) {
  final songsAsync = ref.watch(songsProvider);

  return songsAsync.when(
    data: (songs) {
      final Set<String> artists = {};
      for (final song in songs) {
        for (final artist in song.artists) {
          if (artist.trim().isNotEmpty) {
            artists.add(artist.trim());
          }
        }
      }
      return artists.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Family provider that returns songs for a specific artist
final artistSongsProvider = Provider.family<List<Song>, String>((
  ref,
  artistName,
) {
  final songsAsync = ref.watch(songsProvider);
  final normalizedArtistName = artistName.toLowerCase().trim();

  return songsAsync.when(
    data: (songs) {
      return songs.where((song) {
        return song.artists.any(
          (a) => a.toLowerCase().trim() == normalizedArtistName,
        );
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
