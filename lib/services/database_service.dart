import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:imgrep/utils/debug_logger.dart';

class DatabaseService {
  static Database? _db;

  static Future<void> init() async {
    final db_path = await getDatabasesPath();

    Dbg.i(db_path);

    _db = await openDatabase(
      join(db_path, "imgrep.db"),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE images(
            id TEXT PRIMARY KEY,
            path TEXT,
            modified_at DATE
          );
        ''');
      },
    );
  }

  static Future<Database> get database async {
    if (_db != null) return _db!;
    await init();
    return _db!;
  }

  static Future<void> insertImage(AssetEntity img) async {
    final file = await img.file;
    if (file == null) return;

    final path = file.path;
    final id = img.id;
    final modifiedAt = img.modifiedDateTime.toIso8601String();

    final db = await database;
    await db.insert(
      "images",
      { "id": id, "path": path, "modified_at": modifiedAt },
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  static Future<void> batchInsertImage(List<AssetEntity> imgs) async {
    final db = await database;

    final batch = db!.batch();
    for (final img in imgs) {
      final file = await img.file;
      if (file == null) {
        Dbg.e("Invalid Asset File: $img");
        continue;
      }

      final path = file.path;
      final id = img.id;
      final modifiedAt = img.modifiedDateTime.toIso8601String();

      batch.insert(
        "images",
        { "id": id, "path": path, "modified_at": modifiedAt },
        conflictAlgorithm: ConflictAlgorithm.replace
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<List<String>> getImagesPaginated(int page, int limit) async {
    final db = await database;
    final maps = await db.query(
      "images",
      orderBy: "modified_at DESC",
      offset: page,
      limit: limit,
    );
    return List.generate(maps.length, (i) => maps[i]["id"] as String);
  }

  static Future<void> deleteImage(String id) async {
    final db = await database;
    await db.delete(
      "images",
      where: "id = ?",
      whereArgs: [id],
    );
  }
}
