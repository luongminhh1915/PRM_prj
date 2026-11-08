class RevenueReportItem {
  final String label;
  final double totalRevenue;
  final double cashRevenue;
  final double transferRevenue;
  final int orderCount;

  RevenueReportItem({
    required this.label,
    required this.totalRevenue,
    this.cashRevenue = 0.0,
    this.transferRevenue = 0.0,
    required this.orderCount,
  });

  factory RevenueReportItem.fromJson(Map<String, dynamic> json) {
    return RevenueReportItem(
      label: json['label'] as String? ?? '—',
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      cashRevenue: (json['cashRevenue'] as num?)?.toDouble() ?? 0.0,
      transferRevenue: (json['transferRevenue'] as num?)?.toDouble() ?? 0.0,
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
    );
  }
}
