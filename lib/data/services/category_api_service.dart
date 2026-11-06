import 'package:supermarket_manager_system/data/local/mobile_app_database.dart';
import 'package:supermarket_manager_system/models/category_list_item.dart';

class CategoryApiService {
  Future<List<CategoryListItem>> getCategories() async {
    final db = await MobileAppDatabase.instance.database;
    final rows = await db.query('categories', orderBy: 'id ASC');
    return rows.map((r) {
      return CategoryListItem(
        id: r['id'] as int? ?? 0,
        name: r['name'] as String? ?? '',
        status: r['status'] as String? ?? 'active',
        createdAt: r['created_at']?.toString(),
      );
    }).toList();
  }

  Future<CategoryListItem> getCategoryById(int id) async {
    final db = await MobileAppDatabase.instance.database;
    final rows = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw Exception('Category not found');
    }

    final r = rows.first;
    return CategoryListItem(
      id: r['id'] as int? ?? 0,
      name: r['name'] as String? ?? '',
      status: r['status'] as String? ?? 'active',
      createdAt: r['created_at']?.toString(),
    );
  }

  Future<CategoryListItem> createCategory({
    required String name,
    required String status,
  }) async {
    final db = await MobileAppDatabase.instance.database;
    final nowStr = DateTime.now().toIso8601String();
    final id = await db.insert('categories', {
      'name': name.trim(),
      'status': status.trim().isEmpty ? 'active' : status.trim(),
      'created_at': nowStr,
      'updated_at': nowStr,
    });

    return CategoryListItem(
      id: id,
      name: name.trim(),
      status: status.trim().isEmpty ? 'active' : status.trim(),
      createdAt: nowStr,
    );
  }

  Future<CategoryListItem> updateCategory({
    required int id,
    required String name,
    required String status,
  }) async {
    final db = await MobileAppDatabase.instance.database;
    final nowStr = DateTime.now().toIso8601String();
    final count = await db.update(
      'categories',
      {
        'name': name.trim(),
        'status': status.trim().isEmpty ? 'active' : status.trim(),
        'updated_at': nowStr,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count == 0) {
      throw Exception('Category not found');
    }

    return getCategoryById(id);
  }

  Future<void> deleteCategory(int id) async {
    final db = await MobileAppDatabase.instance.database;
    final count = await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count == 0) {
      throw Exception('Category not found');
    }
  }
}
