import 'package:sqflite/sqflite.dart';
import 'db_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final int? id;
  final String name;
  final String phone;
  final String email;
  final String role; // User or Guardian
  final bool isLoggedIn;
  final String gender;

  User({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    this.isLoggedIn = false,
    required this.gender,
  });

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
      'gender': gender,
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
      gender: map['gender'] ?? '',
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
        isLoggedIn INTEGER,
        gender TEXT
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

  static Future<void> deleteLoggedInUserAndFirestore() async {
    final db = await DBHelper().database;
    final user = await getLoggedInUser();
    if (user != null && user.id != null) {
      // Remove from Firestore (guardian_links and alerts)
      try {
        // Remove user from all guardian_links (where this user is listed as a guardian's user)
        // This is a best-effort cleanup; you may want to adjust for your schema
        final firestore = FirebaseFirestore.instance;
        final guardianLinks = await firestore.collection('guardian_links').get();
        for (final doc in guardianLinks.docs) {
          final guardians = (doc.data()['guardians'] ?? []) as List;
          guardians.removeWhere((g) => (g['userPhone'] ?? '') == user.phone);
          await doc.reference.update({'guardians': guardians});
        }
        // Remove any alert for this user (if you store by user phone)
        await firestore.collection('alerts').doc(user.phone).delete();
      } catch (e) {
        print('Firestore cleanup error: ' + e.toString());
      }
      await db.delete('users', where: 'id = ?', whereArgs: [user.id]);
    }
  }
}
