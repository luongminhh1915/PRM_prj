class CustomerDto {
  const CustomerDto({
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

  factory CustomerDto.fromJson(Map<String, dynamic> json) {
    return CustomerDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '—',
      phone: json['phone'] as String? ?? '—',
      points: (json['points'] as num?)?.toInt() ?? 0,
      totalPurchases: (json['total_purchases'] as num?)?.toInt() ??
          (json['totalPurchases'] as num?)?.toInt() ??
          0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ??
          (json['totalAmount'] as num?)?.toDouble() ??
          0.0,
      discountPercent: (json['discount_percent'] as num?)?.toDouble() ??
          (json['discountPercent'] as num?)?.toDouble() ??
          0.0,
    );
  }
}

class CustomerDetailDto {
  const CustomerDetailDto({
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CustomerDetailDto.fromJson(Map<String, dynamic> json) {
    return CustomerDetailDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '—',
      phone: json['phone'] as String? ?? '—',
      points: (json['points'] as num?)?.toInt() ?? 0,
      totalPurchases: (json['total_purchases'] as num?)?.toInt() ??
          (json['totalPurchases'] as num?)?.toInt() ??
          0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ??
          (json['totalAmount'] as num?)?.toDouble() ??
          0.0,
      discountId: (json['discount_id'] as num?)?.toInt() ??
          (json['discountId'] as num?)?.toInt(),
      discountName: json['discount_name'] as String? ??
          json['discountName'] as String? ??
          '—',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'] as String)
              : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'] as String)
              : null,
    );
  }
}
