import 'package:sqflite/sqflite.dart';
import 'db_helper.dart';

class EmergencyContact {
  final int? id;
  final String name;
  final String phone;
  final String note;
  final bool isPriority;
  final bool isBlocked;

  EmergencyContact({
    this.id,
    required this.name,
    required this.phone,
    this.note = '',
    this.isPriority = false,
    this.isBlocked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'note': note,
      'isPriority': isPriority ? 1 : 0,
      'isBlocked': isBlocked ? 1 : 0,
    };
  }

  static EmergencyContact fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      note: map['note'] ?? '',
      isPriority: map['isPriority'] == 1,
      isBlocked: map['isBlocked'] == 1,
    );
  }
}

class EmergencyContactDB {
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE emergency_contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phone TEXT,
        note TEXT,
        isPriority INTEGER,
        isBlocked INTEGER
      )
    ''');
  }

  static Future<int> insertContact(EmergencyContact contact) async {
    final db = await DBHelper().database;
    return await db.insert('emergency_contacts', contact.toMap());
  }

  static Future<List<EmergencyContact>> getContacts() async {
    final db = await DBHelper().database;
    final maps = await db.query('emergency_contacts');
    return maps.map((map) => EmergencyContact.fromMap(map)).toList();
  }

  static Future<int> deleteContact(int id) async {
    final db = await DBHelper().database;
    return await db.delete('emergency_contacts', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> updateContact(EmergencyContact contact) async {
    final db = await DBHelper().database;
    return await db.update(
      'emergency_contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }
}
