import 'package:supermarket_manager_system/data/local/mobile_app_database.dart';
import 'package:supermarket_manager_system/models/supplier_list_item.dart';
import 'package:supermarket_manager_system/models/product_list_item.dart';

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

  Future<List<ProductListItem>> getSupplierProducts(int supplierId) async {
    final db = await MobileAppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT p.id, p.barcode, p.product_name, c.name as category_name, 
             p.expiry_date, p.selling_price, p.in_stock, p.status
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.supplier_id = ?
      ORDER BY p.id ASC
      ''',
      [supplierId],
    );

    return rows.map((r) {
      return ProductListItem(
        id: r['id'] as int? ?? 0,
        barcode: r['barcode'] as String? ?? '',
        productName: r['product_name'] as String? ?? '—',
        categoryName: r['category_name'] as String? ?? '—',
        expiryDate: r['expiry_date']?.toString() ?? '—',
        sellingPrice: (r['selling_price'] as num?)?.toDouble() ?? 0.0,
        inStock: (r['in_stock'] as num?)?.toInt() ?? 0,
        status: r['status'] as String? ?? 'In Stock',
      );
    }).toList();
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
