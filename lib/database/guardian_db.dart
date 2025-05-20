import 'package:sqflite/sqflite.dart';
import 'db_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Guardian {
  final int? id;
  final String userName;
  final String userPhone;
  final String note;
  final bool isPrimary;
  final bool isBlocked;
  final String email;
  final String password;
  final bool isLoggedIn;
  final bool isFemale;

  Guardian({
    this.id,
    required this.userName,
    required this.userPhone,
    this.note = '',
    this.isPrimary = false,
    this.isBlocked = false,
    required this.email,
    required this.password,
    this.isLoggedIn = false,
    this.isFemale = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userName': userName,
      'userPhone': userPhone,
      'note': note,
      'isPrimary': isPrimary ? 1 : 0,
      'isBlocked': isBlocked ? 1 : 0,
      'email': email,
      'password': password,
      'isLoggedIn': isLoggedIn ? 1 : 0,
      'isFemale': isFemale ? 1 : 0,
    };
  }

  static Guardian fromMap(Map<String, dynamic> map) {
    return Guardian(
      id: map['id'],
      userName: map['userName'],
      userPhone: map['userPhone'],
      note: map['note'] ?? '',
      isPrimary: map['isPrimary'] == 1,
      isBlocked: map['isBlocked'] == 1,
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      isLoggedIn: map['isLoggedIn'] == 1,
      isFemale: (map['isFemale'] ?? 0) == 1,
    );
  }
}

class GuardianDB {
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE guardians (
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
  }

  static Future<int> insertGuardian(Guardian guardian) async {
    final db = await DBHelper().database;
    return await db.insert('guardians', guardian.toMap());
  }

  static Future<List<Guardian>> getGuardians() async {
    final db = await DBHelper().database;
    final maps = await db.query('guardians');
    return maps.map((map) => Guardian.fromMap(map)).toList();
  }

  static Future<int> updateGuardian(Guardian guardian) async {
    final db = await DBHelper().database;
    return await db.update(
      'guardians',
      guardian.toMap(),
      where: 'id = ?',
      whereArgs: [guardian.id],
    );
  }

  static Future<int> deleteGuardian(int id) async {
    final db = await DBHelper().database;
    return await db.delete(
      'guardians',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<Guardian?> getLoggedInGuardian() async {
    final db = await DBHelper().database;
    final maps = await db.query('guardians', where: 'isLoggedIn = ?', whereArgs: [1]);
    if (maps.isNotEmpty) {
      return Guardian.fromMap(maps.first);
    }
    return null;
  }

  static Future<void> logoutAll() async {
    final db = await DBHelper().database;
    await db.update('guardians', {'isLoggedIn': 0});
  }

  static Future<void> setLoggedIn(int guardianId) async {
    final db = await DBHelper().database;
    await db.update('guardians', {'isLoggedIn': 0}); // logout all
    await db.update('guardians', {'isLoggedIn': 1}, where: 'id = ?', whereArgs: [guardianId]);
  }

  static Future<Guardian?> checkGuardianLogin(String email, String password) async {
    final db = await DBHelper().database;
    final maps = await db.query(
      'guardians',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (maps.isNotEmpty) {
      return Guardian.fromMap(maps.first);
    }
    return null;
  }

  static Future<bool> emailExists(String email) async {
    final db = await DBHelper().database;
    final maps = await db.query('guardians', where: 'email = ?', whereArgs: [email]);
    return maps.isNotEmpty;
  }

  static Future<void> deleteLoggedInGuardian() async {
    final db = await DBHelper().database;
    final guardian = await getLoggedInGuardian();
    if (guardian != null && guardian.id != null) {
      await db.delete('guardians', where: 'id = ?', whereArgs: [guardian.id]);
    }
  }

  static Future<void> deleteLoggedInGuardianAndFirestore() async {
    final db = await DBHelper().database;
    final guardian = await getLoggedInGuardian();
    if (guardian != null && guardian.id != null) {
      try {
        final firestore = FirebaseFirestore.instance;
        // Remove guardian_links doc for this guardian
        await firestore.collection('guardian_links').doc(guardian.userPhone).delete();
        // Remove alert doc for this guardian
        await firestore.collection('alerts').doc(guardian.userPhone).delete();
      } catch (e) {
        print('Firestore cleanup error: ' + e.toString());
      }
      await db.delete('guardians', where: 'id = ?', whereArgs: [guardian.id]);
    }
  }

  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add the isFemale column if it doesn't exist
      await db.execute('ALTER TABLE guardians ADD COLUMN isFemale INTEGER DEFAULT 0');
    }
  }

  static getAllGuardians() {}
}
