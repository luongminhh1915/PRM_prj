import 'package:flutter/foundation.dart';
import 'package:supermarket_manager_system/data/local/mobile_app_database.dart';
import 'package:sqflite/sqflite.dart';

class SessionSnapshot {
  const SessionSnapshot({
    required this.userId,
    required this.roleId,
    required this.fullName,
    required this.role,
  });

  final int userId;
  final int roleId;
  final String fullName;
  final String role;
}

class SessionLocalStore {
  SessionLocalStore._();

  static bool get _supportsLocalSqlite {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static Future<SessionSnapshot?> load() async {
    if (!_supportsLocalSqlite) {
      return null;
    }
    final db = await MobileAppDatabase.instance.database;
    final rows = await db.query(
      'session',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.first;
    return SessionSnapshot(
      userId: (row['user_id'] as num).toInt(),
      roleId: (row['role_id'] as num).toInt(),
      fullName: row['full_name'] as String? ?? '',
      role: row['role'] as String? ?? '',
    );
  }

  static Future<void> save({
    required int userId,
    required int roleId,
    required String fullName,
    required String role,
  }) async {
    if (!_supportsLocalSqlite) {
      return;
    }
    final db = await MobileAppDatabase.instance.database;
    await db.insert('session', {
      'id': 1,
      'user_id': userId,
      'role_id': roleId,
      'full_name': fullName,
      'role': role,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> clear() async {
    if (!_supportsLocalSqlite) {
      return;
    }
    final db = await MobileAppDatabase.instance.database;
    await db.delete('session', where: 'id = ?', whereArgs: [1]);
  }
}
