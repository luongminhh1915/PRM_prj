class OrderDto {
  const OrderDto({
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

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    return OrderDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderNo: json['order_no'] as String? ?? json['orderNo'] as String? ?? '—',
      orderDateTime: json['order_date_time'] as String? ??
          json['orderDateTime'] as String? ??
          '—',
      customerName: json['customer_name'] as String? ??
          json['customerName'] as String? ??
          '—',
      customerPhone: json['customer_phone'] as String? ??
          json['customerPhone'] as String? ??
          '—',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (json['discount_percent'] as num?)?.toDouble() ??
          (json['discountPercent'] as num?)?.toDouble() ??
          0.0,
      payable: (json['payable'] as num?)?.toDouble() ?? 0.0,
      paid: (json['paid'] as num?)?.toDouble(),
      paymentMethod: json['payment_method'] as String? ??
          json['paymentMethod'] as String? ??
          'Cash',
      status: json['status'] as String? ?? 'Paid',
      cashierName: json['cashier_name'] as String? ??
          json['cashierName'] as String? ??
          '—',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class OrderDetailItemDto {
  const OrderDetailItemDto({
    required this.productName,
    required this.unitPrice,
    required this.qty,
    required this.amount,
  });

  final String productName;
  final double unitPrice;
  final int qty;
  final double amount;

  factory OrderDetailItemDto.fromJson(Map<String, dynamic> json) {
    return OrderDetailItemDto(
      productName: json['product_name'] as String? ??
          json['productName'] as String? ??
          '—',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ??
          (json['unitPrice'] as num?)?.toDouble() ??
          0.0,
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OrderDetailDto {
  const OrderDetailDto({
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
  final List<OrderDetailItemDto> items;

  factory OrderDetailDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return OrderDetailDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderNo: json['order_no'] as String? ?? '—',
      customerPhone: json['customer_phone'] as String? ?? '—',
      cashierName: json['cashier_name'] as String? ?? '—',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      totalPayment: (json['total_payment'] as num?)?.toDouble() ??
          (json['totalPayable'] as num?)?.toDouble() ??
          0.0,
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(OrderDetailItemDto.fromJson)
              .toList()
          : const [],
    );
  }
}

class DebtDto {
  const DebtDto({
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.totalDebt,
    required this.lastOrderAt,
    required this.status,
  });

  final int customerId;
  final String customerName;
  final String customerPhone;
  final double totalDebt;
  final DateTime? lastOrderAt;
  final String status;
}
