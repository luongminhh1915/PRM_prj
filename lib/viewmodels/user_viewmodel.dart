import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supermarket_manager_system/data/local/mobile_app_database.dart';
import 'package:supermarket_manager_system/dto/user_dto.dart';
import 'package:supermarket_manager_system/mappers/user_mapper.dart';

class UserViewModel extends ChangeNotifier {
  bool isLoading = false;
  List<UserDto> users = const [];
  UserDetailDto? selectedUser;
  String? errorMessage;

  Future<void> loadUsers() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final db = await MobileAppDatabase.instance.database;
      final rows = await db.rawQuery('''
        SELECT u.*, r.name as role_name
        FROM users u
        LEFT JOIN roles r ON u.role_id = r.id
        ORDER BY u.id ASC
      ''');

      users = rows.map(UserMapper.fromRow).toList();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<UserDetailDto> getUserDetail(int userId) async {
    try {
      final db = await MobileAppDatabase.instance.database;
      final rows = await db.rawQuery(
        '''
        SELECT u.*, r.name as role_name
        FROM users u
        LEFT JOIN roles r ON u.role_id = r.id
        WHERE u.id = ?
        LIMIT 1
        ''',
        [userId],
      );

      if (rows.isEmpty) {
        throw Exception('User not found');
      }

      final shifts = await db.query(
        'shifts',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
        limit: 7,
      );

      final detail = UserMapper.fromDetailRow(rows.first, shifts);
      selectedUser = detail;
      return detail;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateUserStatus(int userId, String status) async {
    final db = await MobileAppDatabase.instance.database;
    await db.update(
      'users',
      {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
    await loadUsers();
  }
}

final userViewModelProvider =
    ChangeNotifierProvider<UserViewModel>((ref) => UserViewModel());

