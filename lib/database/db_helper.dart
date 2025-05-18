import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart';


class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<void> _deleteOldDatabaseIfExists() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "women_safety_app.db");

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      print("✅ Old database deleted successfully.");
    } else {
      print("ℹ️ No old database found.");
    }
  }

  Future<Database> _initDb() async {
    await _deleteOldDatabaseIfExists(); // 🔥 DELETE OLD DB ONCE DURING DEV

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'women_safety_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS emergency_contacts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            phone TEXT,
            note TEXT,
            isPriority INTEGER,
            isBlocked INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS guardians (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userName TEXT,
            userPhone TEXT,
            note TEXT,
            isPrimary INTEGER,
            isBlocked INTEGER,
            email TEXT,
            password TEXT,
            isLoggedIn INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            phone TEXT,
            email TEXT,
            role TEXT,
            isLoggedIn INTEGER
          )
        ''');
      },
    );
  }

  Future<void> deleteOldDatabaseIfExists() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'women_safety_app.db');
    await deleteDatabase(path);
  }
}
