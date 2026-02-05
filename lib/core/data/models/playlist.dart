class Playlist {
  final int? id;
  final String name;
  final DateTime createdAt;
  final DateTime modifiedAt;

  const Playlist({
    this.id,
    required this.name,
    required this.createdAt,
    required this.modifiedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'modifiedAt': modifiedAt.millisecondsSinceEpoch,
    };
  }

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(map['modifiedAt'] as int),
    );
  }

  Playlist copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }
}

class PlaylistSong {
  final int? id;
  final int playlistId;
  final int songId;
  final int orderIndex;
  final DateTime addedAt;

  const PlaylistSong({
    this.id,
    required this.playlistId,
    required this.songId,
    required this.orderIndex,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'playlistId': playlistId,
      'songId': songId,
      'orderIndex': orderIndex,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }

  factory PlaylistSong.fromMap(Map<String, dynamic> map) {
    return PlaylistSong(
      id: map['id'] as int?,
      playlistId: map['playlistId'] as int,
      songId: map['songId'] as int,
      orderIndex: map['orderIndex'] as int,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['addedAt'] as int),
    );
  }
}
