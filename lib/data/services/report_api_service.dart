import 'package:supermarket_manager_system/data/local/mobile_app_database.dart';
import 'package:supermarket_manager_system/models/revenue_report_item.dart';

class ReportApiService {
  static const _monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  Future<List<RevenueReportItem>> getRevenueReport({
    required int year,
    int? month,
  }) async {
    final db = await MobileAppDatabase.instance.database;

    if (month != null) {
      return _getReportByDay(db, year, month);
    } else {
      return _getReportByMonth(db, year);
    }
  }

  Future<List<RevenueReportItem>> _getReportByMonth(dynamic db, int year) async {
    final yearStr = '$year';
    final rows = await db.rawQuery(
      '''
      SELECT strftime('%m', order_date) as m, 
             SUM(total_payable) as total_rev, 
             COUNT(id) as ord_count
      FROM sales_orders
      WHERE strftime('%Y', order_date) = ?
      GROUP BY m
      ''',
      [yearStr],
    );

    final Map<int, Map<String, dynamic>> byMonth = {};
    for (final r in rows) {
      final mStr = r['m'] as String?;
      if (mStr != null) {
        final mInt = int.tryParse(mStr);
        if (mInt != null) {
          byMonth[mInt] = r;
        }
      }
    }

    final List<RevenueReportItem> result = [];
    for (int m = 1; m <= 12; m++) {
      final row = byMonth[m];
      final rev = (row?['total_rev'] as num?)?.toDouble() ?? 0.0;
      final count = (row?['ord_count'] as num?)?.toInt() ?? 0;
      result.add(
        RevenueReportItem(
          label: _monthLabels[m - 1],
          totalRevenue: rev,
          orderCount: count,
        ),
      );
    }
    return result;
  }

  Future<List<RevenueReportItem>> _getReportByDay(
    dynamic db,
    int year,
    int month,
  ) async {
    final monthStr = month.toString().padLeft(2, '0');
    final yearMonthStr = '$year-$monthStr';

    final rows = await db.rawQuery(
      '''
      SELECT strftime('%d', order_date) as d, 
             SUM(total_payable) as total_rev, 
             COUNT(id) as ord_count
      FROM sales_orders
      WHERE strftime('%Y-%m', order_date) = ?
      GROUP BY d
      ''',
      [yearMonthStr],
    );

    final Map<int, Map<String, dynamic>> byDay = {};
    for (final r in rows) {
      final dStr = r['d'] as String?;
      if (dStr != null) {
        final dInt = int.tryParse(dStr);
        if (dInt != null) {
          byDay[dInt] = r;
        }
      }
    }

    // Number of days in month
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final List<RevenueReportItem> result = [];
    for (int d = 1; d <= daysInMonth; d++) {
      final row = byDay[d];
      final rev = (row?['total_rev'] as num?)?.toDouble() ?? 0.0;
      final count = (row?['ord_count'] as num?)?.toInt() ?? 0;
      result.add(
        RevenueReportItem(
          label: d.toString().padLeft(2, '0'),
          totalRevenue: rev,
          orderCount: count,
        ),
      );
    }
    return result;
  }
}
