class CustomerListItem {
  const CustomerListItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.points,
    required this.totalPurchases,
    required this.totalAmount,
    required this.discountPercent,
  });

  final int id;
  final String name;
  final String phone;
  final int points;
  final int totalPurchases;
  final double totalAmount;
  final double discountPercent;

  factory CustomerListItem.fromJson(Map<String, dynamic> json) {
    return CustomerListItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '—',
      phone: json['phone'] as String? ?? '—',
      points: (json['points'] as num?)?.toInt() ?? 0,
      totalPurchases: (json['totalPurchases'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
    );
  }
}
