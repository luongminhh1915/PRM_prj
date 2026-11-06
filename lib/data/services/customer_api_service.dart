import 'package:supermarket_manager_system/data/local/mobile_app_database.dart';
import 'package:supermarket_manager_system/models/customer_detail.dart';
import 'package:supermarket_manager_system/models/customer_list_item.dart';
import 'package:supermarket_manager_system/models/order_list_item.dart';

class CustomerApiService {
  Future<List<CustomerListItem>> getCustomers() async {
    final db = await MobileAppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT c.*, d.percent as discount_percent
      FROM customers c
      LEFT JOIN discounts d ON c.discount_id = d.id
      ORDER BY c.name ASC
    ''');

    return rows.map((r) {
      return CustomerListItem(
        id: r['id'] as int? ?? 0,
        name: r['name'] as String? ?? '—',
        phone: r['phone'] as String? ?? '—',
        points: (r['points'] as num?)?.toInt() ?? 0,
        totalPurchases: (r['total_purchases'] as num?)?.toInt() ?? 0,
        totalAmount: (r['total_amount'] as num?)?.toDouble() ?? 0.0,
        discountPercent: (r['discount_percent'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  Future<CustomerDetail> getCustomerDetail(int customerId) async {
    final db = await MobileAppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT c.*, d.name as discount_name
      FROM customers c
      LEFT JOIN discounts d ON c.discount_id = d.id
      WHERE c.id = ?
      LIMIT 1
      ''',
      [customerId],
    );

    if (rows.isEmpty) {
      throw Exception('Customer not found');
    }

    final r = rows.first;
    return CustomerDetail(
      id: r['id'] as int? ?? 0,
      name: r['name'] as String? ?? '—',
      phone: r['phone'] as String? ?? '—',
      points: (r['points'] as num?)?.toInt() ?? 0,
      totalPurchases: (r['total_purchases'] as num?)?.toInt() ?? 0,
      totalAmount: (r['total_amount'] as num?)?.toDouble() ?? 0.0,
      discountId: (r['discount_id'] as num?)?.toInt(),
      discountName: r['discount_name'] as String? ?? '—',
      createdAt: r['created_at']?.toString(),
      updatedAt: r['updated_at']?.toString(),
    );
  }

  Future<CustomerListItem> getCustomerByPhone(String phone) async {
    final db = await MobileAppDatabase.instance.database;
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');

    final rows = await db.rawQuery(
      '''
      SELECT c.*, d.percent as discount_percent
      FROM customers c
      LEFT JOIN discounts d ON c.discount_id = d.id
      WHERE REPLACE(c.phone, ' ', '') = ?
      LIMIT 1
      ''',
      [cleanPhone],
    );

    if (rows.isEmpty) {
      throw Exception('Customer not found by phone');
    }

    final r = rows.first;
    return CustomerListItem(
      id: r['id'] as int? ?? 0,
      name: r['name'] as String? ?? '—',
      phone: r['phone'] as String? ?? '—',
      points: (r['points'] as num?)?.toInt() ?? 0,
      totalPurchases: (r['total_purchases'] as num?)?.toInt() ?? 0,
      totalAmount: (r['total_amount'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (r['discount_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Future<CustomerListItem> createCustomer({
    required String name,
    required String phone,
    double? totalAmount,
  }) async {
    final db = await MobileAppDatabase.instance.database;
    final cleanPhone = phone.trim();

    final existing = await db.query(
      'customers',
      where: 'phone = ?',
      whereArgs: [cleanPhone],
    );
    if (existing.isNotEmpty) {
      throw Exception('Phone number already registered');
    }

    final nowStr = DateTime.now().toIso8601String();
    final id = await db.insert('customers', {
      'name': name.trim(),
      'phone': cleanPhone,
      'points': 0,
      'total_purchases': 0,
      'total_amount': totalAmount ?? 0.0,
      'discount_id': null,
      'created_at': nowStr,
      'updated_at': nowStr,
    });

    return CustomerListItem(
      id: id,
      name: name.trim(),
      phone: cleanPhone,
      points: 0,
      totalPurchases: 0,
      totalAmount: totalAmount ?? 0.0,
      discountPercent: 0.0,
    );
  }

  Future<CustomerListItem> updateCustomer({
    required int customerId,
    required String name,
    required String phone,
    double? totalAmount,
  }) async {
    final db = await MobileAppDatabase.instance.database;
    final cleanPhone = phone.trim();

    final conflict = await db.query(
      'customers',
      where: 'phone = ? AND id != ?',
      whereArgs: [cleanPhone, customerId],
    );
    if (conflict.isNotEmpty) {
      throw Exception('Phone number already used by another customer');
    }

    final nowStr = DateTime.now().toIso8601String();
    final updateData = <String, dynamic>{
      'name': name.trim(),
      'phone': cleanPhone,
      'updated_at': nowStr,
    };
    if (totalAmount != null) {
      updateData['total_amount'] = totalAmount;
    }

    await db.update(
      'customers',
      updateData,
      where: 'id = ?',
      whereArgs: [customerId],
    );

    return getCustomerByPhone(cleanPhone);
  }

  Future<List<OrderListItem>> getCustomerOrderHistory(int customerId) async {
    final db = await MobileAppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT o.*, u.fullname as cashier_name
      FROM sales_orders o
      LEFT JOIN users u ON o.cashier_id = u.id
      WHERE o.customer_id = ?
      ORDER BY o.created_at DESC
      ''',
      [customerId],
    );

    return rows.map((r) {
      final dateStr = r['order_date'] as String? ?? '';
      final timeStr = r['order_time'] as String? ?? '';
      final dateTimeDisplay =
          dateStr.isNotEmpty ? '$dateStr $timeStr'.trim() : '—';
      final createdAtParsed =
          DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now();

      return OrderListItem(
        id: r['id'] as int? ?? 0,
        orderNo: r['order_no'] as String? ?? '—',
        orderDateTime: dateTimeDisplay,
        customerName: r['customer_name'] as String? ?? '—',
        customerPhone: r['customer_phone'] as String? ?? '—',
        total: (r['subtotal'] as num?)?.toDouble() ?? 0.0,
        discountPercent: (r['discount_percent'] as num?)?.toDouble() ?? 0.0,
        payable: (r['total_payable'] as num?)?.toDouble() ?? 0.0,
        paid: (r['paid'] as num?)?.toDouble(),
        paymentMethod: r['payment_method'] as String? ?? 'Cash',
        status: r['status'] as String? ?? 'Paid',
        cashierName: r['cashier_name'] as String? ?? '—',
        createdAt: createdAtParsed,
      );
    }).toList();
  }
}
