import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ImageDB {
  static Database? _db;

  static bool isInitialized = false;

  static Future<void> initialize() async {
    if (isInitialized) return;

    _db = await openDatabase(
      join(await getDatabasesPath(), 'image_cache.db'),
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE images(
            id TEXT PRIMARY KEY,
            path TEXT,
            modified INTEGER,
            added INTEGER
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_modified ON images(modified DESC);
        ''');
      },
      version: 1,
    );
    isInitialized = true;
  }

  static Future<Database> get db async {
    if (_db != null) return _db!;
    await initialize();
    return _db!;
  }

  static Future<void> insert(String id, String path) async {
    final db = await ImageDB.db;
    await db.insert('images', {
      'id': id,
      'path': path,
      'added': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Set<String>> getAllIds() async {
    final rows = await _db!.query('images', columns: ['id']);
    return Set.from(rows.map((r) => r['id'] as String));
  }

  static Future<List<Map>> getAll() async {
    final db = await ImageDB.db;
    return db.query('images');
  }

  static Future<List<Map<String, dynamic>>> getPaginated(
    int limit,
    int offset,
  ) async {
    final db = await ImageDB.db;
    return db.query(
      'images',
      limit: limit,
      offset: offset,
      orderBy: 'modified DESC',
    );
  }

  static Future<int> getImageCount() async {
    final count = await _db!.rawQuery('SELECT COUNT(*) FROM images');
    return Sqflite.firstIntValue(count) ?? 0;
  }

  static Future<void> batchInsert(List<Map<String, dynamic>> images) async {
    final batch = _db!.batch();
    for (final img in images) {
      batch.insert('images', img, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<void> clearAll() async {
    await _db!.delete('images');
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
