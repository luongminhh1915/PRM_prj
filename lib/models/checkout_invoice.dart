class CheckoutInvoiceItem {
  const CheckoutInvoiceItem({
    required this.productName,
    required this.unitPrice,
    required this.qty,
    required this.amount,
  });

  final String productName;
  final double unitPrice;
  final int qty;
  final double amount;

  factory CheckoutInvoiceItem.fromJson(Map<String, dynamic> json) {
    return CheckoutInvoiceItem(
      productName: json['productName'] as String? ?? '—',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CheckoutInvoice {
  const CheckoutInvoice({
    required this.orderId,
    required this.orderNo,
    required this.customerName,
    required this.customerPhone,
    required this.cashierName,
    required this.salesPoint,
    required this.orderDate,
    required this.orderTime,
    required this.subtotal,
    required this.discountPercent,
    required this.discountAmount,
    required this.totalPayable,
    required this.paid,
    required this.balance,
    required this.paymentMethod,
    required this.items,
  });

  final int orderId;
  final String orderNo;
  final String customerName;
  final String customerPhone;
  final String cashierName;
  final String salesPoint;
  final String orderDate;
  final String orderTime;
  final double subtotal;
  final double discountPercent;
  final double discountAmount;
  final double totalPayable;
  final double paid;
  final double balance;
  final String paymentMethod;
  final List<CheckoutInvoiceItem> items;

  factory CheckoutInvoice.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return CheckoutInvoice(
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      orderNo: json['orderNo'] as String? ?? '—',
      customerName: json['customerName'] as String? ?? '—',
      customerPhone: json['customerPhone'] as String? ?? '—',
      cashierName: json['cashierName'] as String? ?? '—',
      salesPoint: json['salesPoint'] as String? ?? '—',
      orderDate: json['orderDate'] as String? ?? '—',
      orderTime: json['orderTime'] as String? ?? '—',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      totalPayable: (json['totalPayable'] as num?)?.toDouble() ?? 0,
      paid: (json['paid'] as num?)?.toDouble() ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] as String? ?? '—',
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(CheckoutInvoiceItem.fromJson)
              .toList()
          : const [],
    );
  }
}
