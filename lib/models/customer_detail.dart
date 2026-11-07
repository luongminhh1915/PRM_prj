class CustomerDetail {
  const CustomerDetail({
    required this.id,
    required this.name,
    required this.phone,
    required this.points,
    required this.totalPurchases,
    required this.totalAmount,
    required this.discountId,
    required this.discountName,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String phone;
  final int points;
  final int totalPurchases;
  final double totalAmount;
  final int? discountId;
  final String discountName;
  final String? createdAt;
  final String? updatedAt;

  factory CustomerDetail.fromJson(Map<String, dynamic> json) {
    return CustomerDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '—',
      phone: json['phone'] as String? ?? '—',
      points: (json['points'] as num?)?.toInt() ?? 0,
      totalPurchases: (json['totalPurchases'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      discountId: (json['discountId'] as num?)?.toInt(),
      discountName: json['discountName'] as String? ?? '—',
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}
