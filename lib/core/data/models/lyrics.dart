import 'dart:convert';

class Lyrics {
  final int? id;
  final int songId;
  final String? plainLyrics;
  final List<LyricLine>? syncedLyrics;
  final String? source; // "Embedded", "LRC", "User"
  final DateTime lastUpdated;
  final String? language;

  const Lyrics({
    this.id,
    required this.songId,
    this.plainLyrics,
    this.syncedLyrics,
    this.source,
    required this.lastUpdated,
    this.language,
  });

  // Serialization for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'songId': songId,
      'plainLyrics': plainLyrics,
      'syncedLyrics': syncedLyrics != null
          ? jsonEncode(syncedLyrics!.map((l) => l.toMap()).toList())
          : null,
      'source': source,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'language': language,
    };
  }

  factory Lyrics.fromMap(Map<String, dynamic> map) {
    return Lyrics(
      id: map['id'] as int?,
      songId: map['songId'] as int,
      plainLyrics: map['plainLyrics'] as String?,
      syncedLyrics: map['syncedLyrics'] != null
          ? (jsonDecode(map['syncedLyrics'] as String) as List)
                .map((e) => LyricLine.fromMap(e as Map<String, dynamic>))
                .toList()
          : null,
      source: map['source'] as String?,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        map['lastUpdated'] as int,
      ),
      language: map['language'] as String?,
    );
  }

  Lyrics copyWith({
    int? id,
    int? songId,
    String? plainLyrics,
    List<LyricLine>? syncedLyrics,
    String? source,
    DateTime? lastUpdated,
    String? language,
  }) {
    return Lyrics(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      plainLyrics: plainLyrics ?? this.plainLyrics,
      syncedLyrics: syncedLyrics ?? this.syncedLyrics,
      source: source ?? this.source,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      language: language ?? this.language,
    );
  }
}

class LyricLine {
  final int timeMs;
  final String text;

  const LyricLine({required this.timeMs, required this.text});

  Map<String, dynamic> toMap() {
    return {'timeMs': timeMs, 'text': text};
  }

  factory LyricLine.fromMap(Map<String, dynamic> map) {
    return LyricLine(timeMs: map['timeMs'] as int, text: map['text'] as String);
  }

  LyricLine copyWith({int? timeMs, String? text}) {
    return LyricLine(timeMs: timeMs ?? this.timeMs, text: text ?? this.text);
  }
}
