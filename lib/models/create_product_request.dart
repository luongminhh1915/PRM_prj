class CreateProductRequest {
  const CreateProductRequest({
    required this.barcode,
    required this.productBatch,
    required this.productName,
    this.description,
    required this.costPrice,
    required this.sellingPrice,
    required this.cartons,
    required this.qtyCartons,
    required this.supplierId,
    required this.categoryId,
    required this.mftDate,
    required this.expiryDate,
    this.imageUrl,
  });

  final String barcode;
  final String productBatch;
  final String productName;
  final String? description;
  final double costPrice;
  final double sellingPrice;
  final int cartons;
  final int qtyCartons;
  final int supplierId;
  final int categoryId;
  final String mftDate;
  final String expiryDate;
  final String? imageUrl;

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'productBatch': productBatch,
      'productName': productName,
      if (description != null && description!.isNotEmpty) 'description': description,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'qtyCartons': cartons,
      'inStock': qtyCartons,
      'supplierId': supplierId,
      'categoryId': categoryId,
      'mftDate': mftDate,
      'expiryDate': expiryDate,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
    };
  }
}
