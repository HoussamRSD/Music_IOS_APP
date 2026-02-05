import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
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

    return await openDatabase(path, version: 1, onCreate: _createDB);
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
}
