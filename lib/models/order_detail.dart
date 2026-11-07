class OrderDetailItem {
  const OrderDetailItem({
    required this.productName,
    required this.unitPrice,
    required this.qty,
    required this.amount,
  });

  final String productName;
  final double unitPrice;
  final int qty;
  final double amount;

  factory OrderDetailItem.fromJson(Map<String, dynamic> json) {
    return OrderDetailItem(
      productName: json['productName'] as String? ?? '—',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class OrderDetail {
  const OrderDetail({
    required this.id,
    required this.orderNo,
    required this.customerPhone,
    required this.cashierName,
    required this.subtotal,
    required this.discountPercent,
    required this.discountAmount,
    required this.totalPayment,
    required this.items,
  });

  final int id;
  final String orderNo;
  final String customerPhone;
  final String cashierName;
  final double subtotal;
  final double discountPercent;
  final double discountAmount;
  final double totalPayment;
  final List<OrderDetailItem> items;

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return OrderDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderNo: json['orderNo'] as String? ?? '—',
      customerPhone: json['customerPhone'] as String? ?? '—',
      cashierName: json['cashierName'] as String? ?? '—',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      totalPayment: (json['totalPayment'] as num?)?.toDouble() ?? 0,
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(OrderDetailItem.fromJson)
              .toList()
          : const [],
    );
  }
}

