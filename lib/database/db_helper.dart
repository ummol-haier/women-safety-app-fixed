import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    try {
      _db = await _initDb();
      return _db!;
    } catch (e) {
      throw Exception("Database initialization failed: \\$e");
    }
  }

  Future<Database> _initDb() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'women_safety_app.db');

      print('Database path: $path'); // Debug log for database path

      return await openDatabase(
        path,
        version: 3,
        onCreate: (db, version) async {
          print('Creating database schema...'); // Debug log for schema creation
          await db.execute('''
            CREATE TABLE IF NOT EXISTS emergency_contacts (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              phone TEXT,
              note TEXT,
              isPriority INTEGER,
              isBlocked INTEGER,
              email TEXT
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
              isLoggedIn INTEGER,
              isFemale INTEGER
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              phone TEXT,
              email TEXT,
              role TEXT,
              isLoggedIn INTEGER,
              gender TEXT NULL
            )
          ''');
          print('Database schema created successfully.'); // Debug log for success
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          print('Upgrading database from version $oldVersion to $newVersion...'); // Debug log for upgrade
          if (oldVersion < 2) {
            await db.execute("ALTER TABLE users ADD COLUMN gender TEXT");
          }
          if (oldVersion < 3) {
            await db.execute("ALTER TABLE guardians ADD COLUMN isFemale INTEGER DEFAULT 0");
          }
          print('Database upgraded successfully.'); // Debug log for success
        },
      );
    } catch (e) {
      print('Error initializing database: $e'); // Debug log for errors
      rethrow;
    }
  }
}
