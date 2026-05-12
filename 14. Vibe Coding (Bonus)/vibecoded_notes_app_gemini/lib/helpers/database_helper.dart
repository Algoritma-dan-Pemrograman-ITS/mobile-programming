import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/note.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4, // Bumped to 4
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER';

    await db.execute('''
CREATE TABLE notes (
  id $idType,
  title $textType,
  content $textType,
  timestamp $textType,
  color $intType,
  is_pinned $intType DEFAULT 0,
  is_archived $intType DEFAULT 0
)
''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE notes ADD COLUMN color INTEGER');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE notes ADD COLUMN is_pinned INTEGER DEFAULT 0');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE notes ADD COLUMN is_archived INTEGER DEFAULT 0');
    }
  }

  Future<int> create(Note note) async {
    final db = await instance.database;
    return await db.insert('notes', note.toMap());
  }

  Future<List<Note>> readAllNotes({bool includeArchived = false}) async {
    final db = await instance.database;
    final orderBy = 'is_pinned DESC, timestamp DESC';
    
    String? whereClause;
    List<dynamic>? whereArgs;

    if (!includeArchived) {
      whereClause = 'is_archived = 0';
    } else {
      whereClause = 'is_archived = 1';
    }

    final result = await db.query(
      'notes', 
      orderBy: orderBy,
      where: whereClause,
      whereArgs: whereArgs,
    );

    return result.map((json) => Note.fromMap(json)).toList();
  }

  Future<int> update(Note note) async {
    final db = await instance.database;

    return db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;

    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
