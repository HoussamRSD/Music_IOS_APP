class Song {
  final int? id;
  final String title;
  final String? album;
  final List<String> artists;
  final int? duration; // milliseconds
  final int? trackNumber;
  final int? discNumber;
  final String? genre;
  final int? year;
  final String filePath; // Local file path
  final String? artworkPath; // Cached artwork path
  final DateTime addedAt;
  final int playCount;
  final DateTime? lastPlayed;
  final String? lyricsId; // Future linking to Lyrics
  final bool hasEmbeddedLyrics;
  final bool hasSyncedLyrics;

  const Song({
    this.id,
    required this.title,
    this.album,
    this.artists = const [],
    this.duration,
    this.trackNumber,
    this.discNumber,
    this.genre,
    this.year,
    required this.filePath,
    this.artworkPath,
    required this.addedAt,
    this.playCount = 0,
    this.lastPlayed,
    this.lyricsId,
    this.hasEmbeddedLyrics = false,
    this.hasSyncedLyrics = false,
  });

  // Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'album': album,
      'artists': artists.join('|'), // Store as pipe-separated
      'duration': duration,
      'trackNumber': trackNumber,
      'discNumber': discNumber,
      'genre': genre,
      'year': year,
      'filePath': filePath,
      'artworkPath': artworkPath,
      'addedAt': addedAt.millisecondsSinceEpoch,
      'playCount': playCount,
      'lastPlayed': lastPlayed?.millisecondsSinceEpoch,
      'lyricsId': lyricsId,
      'hasEmbeddedLyrics': hasEmbeddedLyrics ? 1 : 0,
      'hasSyncedLyrics': hasSyncedLyrics ? 1 : 0,
    };
  }

  // Create from Map (SQLite result)
  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as int?,
      title: map['title'] as String,
      album: map['album'] as String?,
      artists:
          (map['artists'] as String?)
              ?.split('|')
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
      duration: map['duration'] as int?,
      trackNumber: map['trackNumber'] as int?,
      discNumber: map['discNumber'] as int?,
      genre: map['genre'] as String?,
      year: map['year'] as int?,
      filePath: map['filePath'] as String,
      artworkPath: map['artworkPath'] as String?,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['addedAt'] as int),
      playCount: map['playCount'] as int? ?? 0,
      lastPlayed: map['lastPlayed'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastPlayed'] as int)
          : null,
      lyricsId: map['lyricsId'] as String?,
      hasEmbeddedLyrics: (map['hasEmbeddedLyrics'] as int?) == 1,
      hasSyncedLyrics: (map['hasSyncedLyrics'] as int?) == 1,
    );
  }

  // Copy with method for updates
  Song copyWith({
    int? id,
    String? title,
    String? album,
    List<String>? artists,
    int? duration,
    int? trackNumber,
    int? discNumber,
    String? genre,
    int? year,
    String? filePath,
    String? artworkPath,
    DateTime? addedAt,
    int? playCount,
    DateTime? lastPlayed,
    String? lyricsId,
    bool? hasEmbeddedLyrics,
    bool? hasSyncedLyrics,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      album: album ?? this.album,
      artists: artists ?? this.artists,
      duration: duration ?? this.duration,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      filePath: filePath ?? this.filePath,
      artworkPath: artworkPath ?? this.artworkPath,
      addedAt: addedAt ?? this.addedAt,
      playCount: playCount ?? this.playCount,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      lyricsId: lyricsId ?? this.lyricsId,
      hasEmbeddedLyrics: hasEmbeddedLyrics ?? this.hasEmbeddedLyrics,
      hasSyncedLyrics: hasSyncedLyrics ?? this.hasSyncedLyrics,
    );
  }
}
