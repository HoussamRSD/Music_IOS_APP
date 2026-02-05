import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/data/models/lyrics.dart';
import '../../../core/data/models/song.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('glass_music.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE songs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        album TEXT,
        artists TEXT,
        duration INTEGER,
        trackNumber INTEGER,
        discNumber INTEGER,
        genre TEXT,
        year INTEGER,
        filePath TEXT NOT NULL,
        artworkPath TEXT,
        addedAt INTEGER NOT NULL,
        playCount INTEGER DEFAULT 0,
        lastPlayed INTEGER,
        lyricsId TEXT,
        hasEmbeddedLyrics INTEGER DEFAULT 0,
        hasSyncedLyrics INTEGER DEFAULT 0
      )
    ''');

    await _createLyricsTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createLyricsTable(db);
    }
  }

  Future<void> _createLyricsTable(Database db) async {
    await db.execute('''
      CREATE TABLE lyrics(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        songId INTEGER NOT NULL,
        plainLyrics TEXT,
        syncedLyrics TEXT,
        source TEXT,
        lastUpdated INTEGER NOT NULL,
        language TEXT,
        FOREIGN KEY (songId) REFERENCES songs (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertSong(Song song) async {
    final db = await database;
    return await db.insert('songs', song.toMap());
  }

  Future<List<Song>> getAllSongs() async {
    final db = await database;
    final result = await db.query('songs', orderBy: 'addedAt DESC');
    return result.map((json) => Song.fromMap(json)).toList();
  }

  Future<Song?> getSong(int id) async {
    final db = await database;
    final maps = await db.query('songs', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Song.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateSong(Song song) async {
    final db = await database;
    return db.update(
      'songs',
      song.toMap(),
      where: 'id = ?',
      whereArgs: [song.id],
    );
  }

  Future<int> deleteSong(int id) async {
    final db = await database;
    return await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  // Lyrics Methods

  Future<int> insertLyrics(Lyrics lyrics) async {
    final db = await database;
    return await db.insert('lyrics', lyrics.toMap());
  }

  Future<Lyrics?> getLyricsBySongId(int songId) async {
    final db = await database;
    final maps = await db.query(
      'lyrics',
      where: 'songId = ?',
      whereArgs: [songId],
    );

    if (maps.isNotEmpty) {
      return Lyrics.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateLyrics(Lyrics lyrics) async {
    final db = await database;
    return db.update(
      'lyrics',
      lyrics.toMap(),
      where: 'id = ?',
      whereArgs: [lyrics.id],
    );
  }
}
