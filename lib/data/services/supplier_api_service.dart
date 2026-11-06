import 'package:supermarket_manager_system/data/local/mobile_app_database.dart';
import 'package:supermarket_manager_system/models/supplier_list_item.dart';

class SupplierApiService {
  Future<List<SupplierListItem>> getSuppliers() async {
    final db = await MobileAppDatabase.instance.database;
    final rows = await db.query('suppliers', orderBy: 'id ASC');

    return rows.map((r) {
      return SupplierListItem(
        id: r['id'] as int? ?? 0,
        supplierName: r['supplier_name'] as String? ?? '—',
        companyName: r['company_name'] as String? ?? '—',
        email: r['email'] as String? ?? '—',
        phone: r['phone'] as String? ?? '—',
        address: r['address'] as String? ?? '—',
        status: r['status'] as String? ?? 'active',
        createdAt: r['created_at']?.toString(),
      );
    }).toList();
  }

  Future<SupplierListItem> getSupplierById(int id) async {
    final db = await MobileAppDatabase.instance.database;
    final rows = await db.query(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw Exception('Supplier not found');
    }

    final r = rows.first;
    return SupplierListItem(
      id: r['id'] as int? ?? 0,
      supplierName: r['supplier_name'] as String? ?? '—',
      companyName: r['company_name'] as String? ?? '—',
      email: r['email'] as String? ?? '—',
      phone: r['phone'] as String? ?? '—',
      address: r['address'] as String? ?? '—',
      status: r['status'] as String? ?? 'active',
      createdAt: r['created_at']?.toString(),
    );
  }

  Future<void> createSupplier({
    required String supplierName,
    String? companyName,
    String? email,
    String? phone,
    String? address,
    String? status,
  }) async {
    final db = await MobileAppDatabase.instance.database;
    final nowStr = DateTime.now().toIso8601String();

    await db.insert('suppliers', {
      'supplier_name': supplierName.trim(),
      'company_name': companyName?.trim().isEmpty ?? true ? null : companyName!.trim(),
      'email': email?.trim().isEmpty ?? true ? null : email!.trim(),
      'phone': phone?.trim().isEmpty ?? true ? null : phone!.trim(),
      'address': address?.trim().isEmpty ?? true ? null : address!.trim(),
      'status': status?.trim().isEmpty ?? true ? 'active' : status!.trim(),
      'created_at': nowStr,
      'updated_at': nowStr,
    });
  }

  Future<void> updateSupplier({
    required int id,
    required String supplierName,
    String? companyName,
    String? email,
    String? phone,
    String? address,
    String? status,
  }) async {
    final db = await MobileAppDatabase.instance.database;
    final nowStr = DateTime.now().toIso8601String();

    final count = await db.update(
      'suppliers',
      {
        'supplier_name': supplierName.trim(),
        'company_name': companyName?.trim().isEmpty ?? true ? null : companyName!.trim(),
        'email': email?.trim().isEmpty ?? true ? null : email!.trim(),
        'phone': phone?.trim().isEmpty ?? true ? null : phone!.trim(),
        'address': address?.trim().isEmpty ?? true ? null : address!.trim(),
        'status': status?.trim().isEmpty ?? true ? 'active' : status!.trim(),
        'updated_at': nowStr,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count == 0) {
      throw Exception('Supplier not found');
    }
  }

  Future<void> deleteSupplier(int id) async {
    final db = await MobileAppDatabase.instance.database;
    final count = await db.delete(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count == 0) {
      throw Exception('Supplier not found');
    }
  }
}
