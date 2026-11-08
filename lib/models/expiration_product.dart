class ExpirationProduct {
  const ExpirationProduct({
    required this.id,
    required this.productName,
    required this.inStock,
    required this.supplierName,
    required this.expiryDate,
    required this.status,
  });

  final int id;
  final String productName;
  final int inStock;
  final String supplierName;
  final String expiryDate;
  final String status;

  factory ExpirationProduct.fromJson(Map<String, dynamic> json) {
    return ExpirationProduct(
      id: (json['id'] as num?)?.toInt() ?? 0,
      productName: json['productName'] as String? ?? '',
      inStock: (json['inStock'] as num?)?.toInt() ?? 0,
      supplierName: json['supplierName'] as String? ?? '',
      expiryDate: (json['expiryDate'] ?? '').toString(),
      status: json['status'] as String? ?? '',
    );
  }
}
