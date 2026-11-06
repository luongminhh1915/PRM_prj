import 'package:sqflite/sqflite.dart';
import 'package:supermarket_manager_system/data/local/mobile_app_database.dart';
import 'package:supermarket_manager_system/models/checkout_invoice.dart';
import 'package:supermarket_manager_system/models/dashboard_summary.dart';
import 'package:supermarket_manager_system/models/dashboard_transaction.dart';
import 'package:supermarket_manager_system/models/order_detail.dart';
import 'package:supermarket_manager_system/models/order_list_item.dart';

class OrderApiService {
  Future<List<OrderListItem>> getOrders() async {
    final db = await MobileAppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT o.*, u.fullname as cashier_name
      FROM sales_orders o
      LEFT JOIN users u ON o.cashier_id = u.id
      ORDER BY o.created_at DESC
    ''');

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

  Future<OrderDetail> getOrderDetail(int orderId) async {
    final db = await MobileAppDatabase.instance.database;
    final orderRows = await db.rawQuery(
      '''
      SELECT o.*, u.fullname as cashier_name
      FROM sales_orders o
      LEFT JOIN users u ON o.cashier_id = u.id
      WHERE o.id = ?
      LIMIT 1
      ''',
      [orderId],
    );

    if (orderRows.isEmpty) {
      throw Exception('Order not found');
    }

    final o = orderRows.first;
    final itemRows = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );

    final items = itemRows.map((it) {
      return OrderDetailItem(
        productName: it['product_name'] as String? ?? '—',
        unitPrice: (it['unit_price'] as num?)?.toDouble() ?? 0.0,
        qty: (it['qty'] as num?)?.toInt() ?? 0,
        amount: (it['amount'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    return OrderDetail(
      id: o['id'] as int? ?? 0,
      orderNo: o['order_no'] as String? ?? '—',
      customerPhone: o['customer_phone'] as String? ?? '—',
      cashierName: o['cashier_name'] as String? ?? '—',
      subtotal: (o['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (o['discount_percent'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (o['discount_amount'] as num?)?.toDouble() ?? 0.0,
      totalPayment: (o['total_payable'] as num?)?.toDouble() ?? 0.0,
      items: items,
    );
  }

  Future<DashboardSummary> getDashboardSummary() async {
    final db = await MobileAppDatabase.instance.database;
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final monthPrefix =
        "${now.year}-${now.month.toString().padLeft(2, '0')}";
    final yearPrefix = "${now.year}";

    final allOrders = await db.query('sales_orders');

    double todaySales = 0.0;
    int todayInvoiceCount = 0;
    double currentMonthSales = 0.0;
    double currentYearRevenue = 0.0;
    double last3MonthSales = 0.0;
    double last6MonthSales = 0.0;

    final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);
    final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);

    for (final o in allOrders) {
      final dateStr = (o['order_date'] as String? ?? '').trim();
      final payable = (o['total_payable'] as num?)?.toDouble() ?? 0.0;
      final orderDate = DateTime.tryParse(dateStr);

      if (dateStr == todayStr) {
        todaySales += payable;
        todayInvoiceCount++;
      }
      if (dateStr.startsWith(monthPrefix)) {
        currentMonthSales += payable;
      }
      if (dateStr.startsWith(yearPrefix)) {
        currentYearRevenue += payable;
      }
      if (orderDate != null) {
        if (!orderDate.isBefore(threeMonthsAgo)) {
          last3MonthSales += payable;
        }
        if (!orderDate.isBefore(sixMonthsAgo)) {
          last6MonthSales += payable;
        }
      }
    }

    final userCountResult =
        await db.rawQuery('SELECT COUNT(*) as count FROM users');
    final userCount =
        Sqflite.firstIntValue(userCountResult) ?? 0;

    final supplierCountResult =
        await db.rawQuery('SELECT COUNT(*) as count FROM suppliers');
    final supplierCount =
        Sqflite.firstIntValue(supplierCountResult) ?? 0;

    final availableProductsResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE in_stock > 0',
    );
    final availableProductsCount =
        Sqflite.firstIntValue(availableProductsResult) ?? 0;

    final expiredProductsResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE expiry_date < ?',
      [todayStr],
    );
    final expiredProducts =
        Sqflite.firstIntValue(expiredProductsResult) ?? 0;

    final productsCountResult =
        await db.rawQuery('SELECT COUNT(*) as count FROM products');
    final newProductsCount =
        Sqflite.firstIntValue(productsCountResult) ?? 0;

    final topProductRows = await db.rawQuery('''
      SELECT product_name, SUM(qty) as total_qty
      FROM order_items
      GROUP BY product_name
      ORDER BY total_qty DESC
      LIMIT 5
    ''');

    final topProducts = topProductRows.map((r) {
      return TopProduct(
        name: r['product_name'] as String? ?? '—',
        totalQty: (r['total_qty'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    return DashboardSummary(
      todaySales: todaySales,
      expiredProducts: expiredProducts,
      todayInvoiceCount: todayInvoiceCount,
      newProductsCount: newProductsCount,
      supplierCount: supplierCount,
      invoiceCount: allOrders.length,
      currentMonthSales: currentMonthSales,
      last3MonthSales: last3MonthSales,
      last6MonthSales: last6MonthSales,
      userCount: userCount,
      availableProductsCount: availableProductsCount,
      currentYearRevenue: currentYearRevenue,
      topProducts: topProducts,
    );
  }

  Future<List<DashboardTransaction>> getTodayTransactions() async {
    final db = await MobileAppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT o.*, u.fullname as cashier_name
      FROM sales_orders o
      LEFT JOIN users u ON o.cashier_id = u.id
      ORDER BY o.created_at DESC
      LIMIT 10
    ''');

    return rows.map((r) {
      return DashboardTransaction(
        orderNo: r['order_no'] as String? ?? '—',
        paymentMethod: r['payment_method'] as String? ?? 'Cash',
        totalPayable: (r['total_payable'] as num?)?.toDouble() ?? 0.0,
        cashierName: r['cashier_name'] as String? ?? '—',
        status: r['status'] as String? ?? 'Paid',
        createdAt: r['created_at']?.toString() ?? '',
      );
    }).toList();
  }

  Future<CheckoutInvoice> checkout({
    required int cashierId,
    required String customerName,
    required String customerPhone,
    required String paymentMethod,
    required double paid,
    required double discountPercent,
    int? discountId,
    String salesPoint = 'Main Store',
    required List<Map<String, dynamic>> items,
  }) async {
    final db = await MobileAppDatabase.instance.database;

    final cashierRows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [cashierId],
      limit: 1,
    );
    final cashierName = cashierRows.isNotEmpty
        ? (cashierRows.first['fullname'] as String? ?? 'Cashier')
        : 'Cashier';

    final cleanPhone = customerPhone.trim();
    int? customerId;
    if (cleanPhone.isNotEmpty) {
      final cRows = await db.query(
        'customers',
        where: 'phone = ?',
        whereArgs: [cleanPhone],
        limit: 1,
      );
      if (cRows.isNotEmpty) {
        customerId = cRows.first['id'] as int?;
      }
    }

    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    final orderNo =
        "INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}";

    double subtotal = 0.0;
    final List<Map<String, dynamic>> processedItems = [];

    for (final item in items) {
      final productId = item['productId'] as int? ?? 0;
      final qty = (item['qty'] as num?)?.toInt() ?? 1;
      final kg = (item['kg'] as num?)?.toDouble() ?? 1.0;
      if (qty <= 0) continue;

      final pRows = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      if (pRows.isEmpty) {
        throw Exception('Product not found: $productId');
      }

      final p = pRows.first;
      final inStock = (p['in_stock'] as num?)?.toInt() ?? 0;
      if (qty > inStock) {
        throw Exception(
          'Insufficient stock for product: ${p['product_name']}',
        );
      }

      final unitPrice = (p['selling_price'] as num?)?.toDouble() ?? 0.0;
      final lineAmount = unitPrice * qty * (kg > 0 ? kg : 1.0);
      subtotal += lineAmount;

      await db.update(
        'products',
        {'in_stock': inStock - qty},
        where: 'id = ?',
        whereArgs: [productId],
      );

      processedItems.add({
        'productId': productId,
        'productName': p['product_name'] as String? ?? '—',
        'unitPrice': unitPrice,
        'qty': qty,
        'amount': lineAmount,
      });
    }

    if (processedItems.isEmpty) {
      throw Exception('No billable items in order.');
    }

    double percent = discountPercent < 0 ? 0 : (discountPercent > 100 ? 100 : discountPercent);
    final discountAmount = subtotal * (percent / 100.0);
    final totalPayable = subtotal - discountAmount;
    final balance = totalPayable - paid;
    final status = balance > 0 ? 'Pending' : 'Paid';
    final payDueDate = balance > 0
        ? now.add(const Duration(days: 7)).toIso8601String().split('T')[0]
        : null;

    final orderId = await db.insert('sales_orders', {
      'order_no': orderNo,
      'customer_id': customerId,
      'customer_phone': cleanPhone.isEmpty ? null : cleanPhone,
      'customer_name': customerName.trim().isEmpty ? 'Guest' : customerName.trim(),
      'cashier_id': cashierId,
      'sales_point': salesPoint,
      'shift_id': 1,
      'order_date': todayStr,
      'order_time': timeStr,
      'subtotal': subtotal,
      'discount_id': discountId,
      'voucher_id': null,
      'discount_percent': percent,
      'discount_amount': discountAmount,
      'total_payable': totalPayable,
      'paid': paid,
      'balance': balance < 0 ? 0.0 : balance,
      'payment_method': paymentMethod.trim().isEmpty ? 'Cash' : paymentMethod.trim(),
      'status': status,
      'pay_due_date': payDueDate,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    final invoiceItems = <CheckoutInvoiceItem>[];
    for (final item in processedItems) {
      await db.insert('order_items', {
        'order_id': orderId,
        'product_id': item['productId'],
        'product_name': item['productName'],
        'unit_price': item['unitPrice'],
        'qty': item['qty'],
        'amount': item['amount'],
      });

      invoiceItems.add(
        CheckoutInvoiceItem(
          productName: item['productName'] as String,
          unitPrice: item['unitPrice'] as double,
          qty: item['qty'] as int,
          amount: item['amount'] as double,
        ),
      );
    }

    if (customerId != null) {
      final cRows = await db.query(
        'customers',
        where: 'id = ?',
        whereArgs: [customerId],
        limit: 1,
      );
      if (cRows.isNotEmpty) {
        final c = cRows.first;
        final currentPts = (c['points'] as num?)?.toInt() ?? 0;
        final currentPurchases = (c['total_purchases'] as num?)?.toInt() ?? 0;
        final currentAmount = (c['total_amount'] as num?)?.toDouble() ?? 0.0;
        final earnedPts = (totalPayable / 1000).floor();

        await db.update(
          'customers',
          {
            'points': currentPts + (earnedPts > 0 ? earnedPts : 0),
            'total_purchases': currentPurchases + 1,
            'total_amount': currentAmount + totalPayable,
            'updated_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [customerId],
        );
      }
    }

    return CheckoutInvoice(
      orderId: orderId,
      orderNo: orderNo,
      customerName: customerName.trim().isEmpty ? 'Guest' : customerName.trim(),
      customerPhone: cleanPhone.isEmpty ? '—' : cleanPhone,
      cashierName: cashierName,
      salesPoint: salesPoint,
      orderDate: todayStr,
      orderTime: timeStr,
      subtotal: subtotal,
      discountPercent: percent,
      discountAmount: discountAmount,
      totalPayable: totalPayable,
      paid: paid,
      balance: balance < 0 ? 0.0 : balance,
      paymentMethod: paymentMethod.trim().isEmpty ? 'Cash' : paymentMethod.trim(),
      items: invoiceItems,
    );
  }
}
