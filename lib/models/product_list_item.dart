class ProductListItem {
  const ProductListItem({
    required this.id,
    required this.barcode,
    required this.productName,
    required this.categoryName,
    required this.expiryDate,
    required this.sellingPrice,
    required this.inStock,
    required this.status,
  });

  final int id;
  final String barcode;
  final String productName;
  final String categoryName;
  final String expiryDate;
  final double sellingPrice;
  final int inStock;
  final String status;

  factory ProductListItem.fromJson(Map<String, dynamic> json) {
    return ProductListItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      barcode: json['barcode'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      expiryDate: (json['expiryDate'] ?? '').toString(),
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0,
      inStock: (json['inStock'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? '',
    );
  }
}

