class DashboardTransaction {
  final String orderNo;
  final String paymentMethod;
  final double totalPayable;
  final String cashierName;
  final String status;
  final String createdAt;

  DashboardTransaction({
    required this.orderNo,
    required this.paymentMethod,
    required this.totalPayable,
    required this.cashierName,
    required this.status,
    required this.createdAt,
  });

  factory DashboardTransaction.fromJson(Map<String, dynamic> json) {
    return DashboardTransaction(
      orderNo: json['orderNo']?.toString() ?? '—',
      paymentMethod: json['paymentMethod']?.toString() ?? '—',
      totalPayable: _toDouble(json['totalPayable']),
      cashierName: json['cashierName']?.toString() ?? '—',
      status: json['status']?.toString() ?? '—',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
