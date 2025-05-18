import 'package:sqflite/sqflite.dart';
import 'db_helper.dart';

class User {
  final int? id;
  final String name;
  final String phone;
  final String email;
  final String role; // User or Guardian
  final bool isLoggedIn;

  User({this.id, required this.name, required this.phone, required this.email, required this.role, this.isLoggedIn = false});

  // Always normalize phone number before saving toMap
  Map<String, dynamic> toMap() {
    String normalizePhone(String phone) {
      String p = phone.replaceAll(RegExp(r'[^0-9+]'), '');
      if (p.startsWith('0')) {
        p = '+88' + p.substring(1);
      } else if (!p.startsWith('+88')) {
        p = '+88' + p;
      }
      return p;
    }
    return {
      'id': id,
      'name': name,
      'phone': normalizePhone(phone),
      'email': email,
      'role': role,
      'isLoggedIn': isLoggedIn ? 1 : 0,
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    String normalizePhone(String phone) {
      String p = phone.replaceAll(RegExp(r'[^0-9+]'), '');
      if (p.startsWith('0')) {
        p = '+88' + p.substring(1);
      } else if (!p.startsWith('+88')) {
        p = '+88' + p;
      }
      return p;
    }
    return User(
      id: map['id'],
      name: map['name'],
      phone: normalizePhone(map['phone']),
      email: map['email'],
      role: map['role'],
      isLoggedIn: map['isLoggedIn'] == 1,
    );
  }
}

class UserDB {
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phone TEXT,
        email TEXT,
        role TEXT,
        isLoggedIn INTEGER
      )
    ''');
  }

  static Future<int> insertUser(User user) async {
    final db = await DBHelper().database;
    return await db.insert('users', user.toMap());
  }

  static Future<List<User>> getUsers() async {
    final db = await DBHelper().database;
    final maps = await db.query('users');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  static Future<User?> getLoggedInUser() async {
    final db = await DBHelper().database;
    final maps = await db.query('users', where: 'isLoggedIn = ?', whereArgs: [1]);
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  static Future<void> logoutAll() async {
    final db = await DBHelper().database;
    await db.update('users', {'isLoggedIn': 0});
  }

  static Future<void> setLoggedIn(int userId) async {
    final db = await DBHelper().database;
    await db.update('users', {'isLoggedIn': 0}); // logout all
    await db.update('users', {'isLoggedIn': 1}, where: 'id = ?', whereArgs: [userId]);
  }

  static Future<void> deleteLoggedInUser() async {
    final db = await DBHelper().database;
    final user = await getLoggedInUser();
    if (user != null && user.id != null) {
      await db.delete('users', where: 'id = ?', whereArgs: [user.id]);
    }
  }
}
