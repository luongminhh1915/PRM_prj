class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.barcode,
    required this.productName,
    required this.productBatch,
    required this.description,
    required this.costPrice,
    required this.sellingPrice,
    required this.qtyCartons,
    required this.inStock,
    required this.supplierName,
    required this.categoryName,
    required this.mftDate,
    required this.expiryDate,
    required this.status,
    required this.imageUrl,
  });

  final int id;
  final String barcode;
  final String productName;
  final String productBatch;
  final String description;
  final double? costPrice;
  final double sellingPrice;
  final int? qtyCartons;
  final int inStock;
  final String supplierName;
  final String categoryName;
  final String mftDate;
  final String expiryDate;
  final String status;
  final String imageUrl;

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      barcode: json['barcode'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      productBatch: json['productBatch'] as String? ?? '',
      description: json['description'] as String? ?? '',
      costPrice: (json['costPrice'] as num?)?.toDouble(),
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0,
      qtyCartons: (json['qtyCartons'] as num?)?.toInt(),
      inStock: (json['inStock'] as num?)?.toInt() ?? 0,
      supplierName: json['supplierName'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      mftDate: (json['mftDate'] ?? '').toString(),
      expiryDate: (json['expiryDate'] ?? '').toString(),
      status: json['status'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }
}

