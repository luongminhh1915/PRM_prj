class OrderListItem {
  const OrderListItem({
    required this.id,
    required this.orderNo,
    required this.orderDateTime,
    required this.customerName,
    required this.customerPhone,
    required this.total,
    required this.discountPercent,
    required this.payable,
    required this.paid,
    required this.paymentMethod,
    required this.status,
    required this.cashierName,
    required this.createdAt,
  });

  final int id;
  final String orderNo;
  final String orderDateTime;
  final String customerName;
  final String customerPhone;
  final double total;
  final double discountPercent;
  final double payable;
  final double? paid;
  final String paymentMethod;
  final String status;
  final String cashierName;
  final DateTime createdAt;

  factory OrderListItem.fromJson(Map<String, dynamic> json) {
    return OrderListItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderNo: json['orderNo'] as String? ?? '—',
      orderDateTime: json['orderDateTime'] as String? ?? '—',
      customerName: json['customerName'] as String? ?? '—',
      customerPhone: json['customerPhone'] as String? ?? '—',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
      payable: (json['payable'] as num?)?.toDouble() ?? 0,
      paid: (json['paid'] as num?)?.toDouble(),
      paymentMethod: json['paymentMethod'] as String? ?? '—',
      status: json['status'] as String? ?? '—',
      cashierName: json['cashierName'] as String? ?? '—',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

