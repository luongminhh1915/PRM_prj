import 'package:supermarket_manager_system/data/local/mobile_app_database.dart';
import 'package:supermarket_manager_system/models/expiration_product.dart';
import 'package:supermarket_manager_system/models/expiration_stats.dart';

class ExpirationApiService {
  Future<ExpirationStats> getExpirationStats() async {
    final db = await MobileAppDatabase.instance.database;
    final products = await db.rawQuery('''
      SELECT p.*, s.supplier_name
      FROM products p
      LEFT JOIN suppliers s ON p.supplier_id = s.id
    ''');

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final in7Days = today.add(const Duration(days: 7));
    final in3Months = DateTime(today.year, today.month + 3, today.day);
    final in6Months = DateTime(today.year, today.month + 6, today.day);

    int expiresToday = 0;
    int expiresIn7Days = 0;
    int expiresIn3Months = 0;
    int expiresIn6Months = 0;

    for (final p in products) {
      final expStr = p['expiry_date'] as String?;
      if (expStr == null || expStr.trim().isEmpty) continue;
      final exp = DateTime.tryParse(expStr.trim());
      if (exp == null) continue;
      final expDate = DateTime(exp.year, exp.month, exp.day);

      if (expDate.isAtSameMomentAs(today)) {
        expiresToday++;
      }
      if (!expDate.isBefore(today) && !expDate.isAfter(in7Days)) {
        expiresIn7Days++;
      }
      if (!expDate.isBefore(today) && !expDate.isAfter(in3Months)) {
        expiresIn3Months++;
      }
      if (!expDate.isBefore(today) && !expDate.isAfter(in6Months)) {
        expiresIn6Months++;
      }
    }

    return ExpirationStats(
      expiresToday: expiresToday,
      expiresIn7Days: expiresIn7Days,
      expiresIn3Months: expiresIn3Months,
      expiresIn6Months: expiresIn6Months,
    );
  }

  Future<List<ExpirationProduct>> getProductsExpiringToday() async {
    return _filterProducts((expDate, today, in7, in3M, in6M) {
      return expDate.isAtSameMomentAs(today);
    });
  }

  Future<List<ExpirationProduct>> getProductsExpiringIn7Days() async {
    return _filterProducts((expDate, today, in7, in3M, in6M) {
      return !expDate.isBefore(today) && !expDate.isAfter(in7);
    });
  }

  Future<List<ExpirationProduct>> getProductsExpiringIn3Months() async {
    return _filterProducts((expDate, today, in7, in3M, in6M) {
      return !expDate.isBefore(today) && !expDate.isAfter(in3M);
    });
  }

  Future<List<ExpirationProduct>> getProductsExpiringIn6Months() async {
    return _filterProducts((expDate, today, in7, in3M, in6M) {
      return !expDate.isBefore(today) && !expDate.isAfter(in6M);
    });
  }

  Future<List<ExpirationProduct>> _filterProducts(
    bool Function(
      DateTime expDate,
      DateTime today,
      DateTime in7,
      DateTime in3M,
      DateTime in6M,
    )
    matcher,
  ) async {
    final db = await MobileAppDatabase.instance.database;
    final products = await db.rawQuery('''
      SELECT p.*, s.supplier_name
      FROM products p
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      ORDER BY p.expiry_date ASC
    ''');

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final in7Days = today.add(const Duration(days: 7));
    final in3Months = DateTime(today.year, today.month + 3, today.day);
    final in6Months = DateTime(today.year, today.month + 6, today.day);

    final List<ExpirationProduct> list = [];
    for (final p in products) {
      final expStr = p['expiry_date'] as String?;
      if (expStr == null || expStr.trim().isEmpty) continue;
      final exp = DateTime.tryParse(expStr.trim());
      if (exp == null) continue;
      final expDate = DateTime(exp.year, exp.month, exp.day);

      if (matcher(expDate, today, in7Days, in3Months, in6Months)) {
        final daysUntil = expDate.difference(today).inDays;
        String status = 'OK';
        if (daysUntil < 0) {
          status = 'Expired';
        } else if (daysUntil == 0) {
          status = 'Expires Today';
        } else if (daysUntil <= 7) {
          status = 'Soon';
        } else if (daysUntil <= 30) {
          status = 'Warning';
        }

        list.add(
          ExpirationProduct(
            id: p['id'] as int? ?? 0,
            productName: p['product_name'] as String? ?? '—',
            inStock: (p['in_stock'] as num?)?.toInt() ?? 0,
            supplierName: p['supplier_name'] as String? ?? '—',
            expiryDate: expStr,
            status: status,
          ),
        );
      }
    }
    return list;
  }
}
