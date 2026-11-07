class DashboardSummary {
  final double todaySales;
  final int expiredProducts;
  final int todayInvoiceCount;
  final int newProductsCount;
  final int supplierCount;
  final int invoiceCount;
  final double currentMonthSales;
  final double last3MonthSales;
  final double last6MonthSales;
  final int userCount;
  final int availableProductsCount;
  final double currentYearRevenue;
  final List<TopProduct> topProducts;

  DashboardSummary({
    required this.todaySales,
    required this.expiredProducts,
    required this.todayInvoiceCount,
    required this.newProductsCount,
    required this.supplierCount,
    required this.invoiceCount,
    required this.currentMonthSales,
    required this.last3MonthSales,
    required this.last6MonthSales,
    required this.userCount,
    required this.availableProductsCount,
    required this.currentYearRevenue,
    required this.topProducts,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    var topList = json['topProducts'] as List?;
    List<TopProduct> topProducts = topList != null
        ? topList.map((i) => TopProduct.fromJson(i)).toList()
        : [];

    return DashboardSummary(
      todaySales: _toDouble(json['todaySales']),
      expiredProducts: _toInt(json['expiredProducts']),
      todayInvoiceCount: _toInt(json['todayInvoiceCount']),
      newProductsCount: _toInt(json['newProductsCount']),
      supplierCount: _toInt(json['supplierCount']),
      invoiceCount: _toInt(json['invoiceCount']),
      currentMonthSales: _toDouble(json['currentMonthSales']),
      last3MonthSales: _toDouble(json['last3MonthSales']),
      last6MonthSales: _toDouble(json['last6MonthSales']),
      userCount: _toInt(json['userCount']),
      availableProductsCount: _toInt(json['availableProductsCount']),
      currentYearRevenue: _toDouble(json['currentYearRevenue']),
      topProducts: topProducts,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

class TopProduct {
  final String name;
  final int totalQty;

  TopProduct({required this.name, required this.totalQty});

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      name: json['name'] ?? '—',
      totalQty: (json['totalQty'] as num?)?.toInt() ?? 0,
    );
  }
}
