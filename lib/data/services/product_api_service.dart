import 'package:supermarket_manager_system/data/local/mobile_app_database.dart';
import 'package:supermarket_manager_system/models/category_option.dart';
import 'package:supermarket_manager_system/models/create_product_request.dart';
import 'package:supermarket_manager_system/models/product_detail.dart';
import 'package:supermarket_manager_system/models/product_list_item.dart';
import 'package:supermarket_manager_system/models/supplier_option.dart';
import 'package:supermarket_manager_system/models/update_product_request.dart';

class ProductApiService {
  Future<List<ProductListItem>> getProducts() async {
    final db = await MobileAppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT p.*, c.name as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      ORDER BY p.id ASC
    ''');

    return rows.map((r) {
      return ProductListItem(
        id: r['id'] as int? ?? 0,
        barcode: r['barcode'] as String? ?? '',
        productName: r['product_name'] as String? ?? '—',
        categoryName: r['category_name'] as String? ?? '—',
        expiryDate: r['expiry_date']?.toString() ?? '',
        sellingPrice: (r['selling_price'] as num?)?.toDouble() ?? 0.0,
        inStock: (r['in_stock'] as num?)?.toInt() ?? 0,
        status: r['status'] as String? ?? 'In Stock',
      );
    }).toList();
  }

  Future<ProductDetail> getProductById(int id) async {
    final db = await MobileAppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT p.*, c.name as category_name, s.supplier_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      WHERE p.id = ?
      LIMIT 1
      ''',
      [id],
    );

    if (rows.isEmpty) {
      throw Exception('Product not found');
    }

    final r = rows.first;
    return ProductDetail(
      id: r['id'] as int? ?? 0,
      barcode: r['barcode'] as String? ?? '',
      productName: r['product_name'] as String? ?? '',
      productBatch: r['product_batch'] as String? ?? '',
      description: r['description'] as String? ?? '',
      costPrice: (r['cost_price'] as num?)?.toDouble(),
      sellingPrice: (r['selling_price'] as num?)?.toDouble() ?? 0.0,
      qtyCartons: (r['qty_cartons'] as num?)?.toInt(),
      inStock: (r['in_stock'] as num?)?.toInt() ?? 0,
      supplierName: r['supplier_name'] as String? ?? '—',
      categoryName: r['category_name'] as String? ?? '—',
      mftDate: r['mft_date']?.toString() ?? '',
      expiryDate: r['expiry_date']?.toString() ?? '',
      status: r['status'] as String? ?? 'In Stock',
      imageUrl: r['image_url'] as String? ?? '',
    );
  }

  Future<ProductDetail> createProduct(CreateProductRequest request) async {
    final db = await MobileAppDatabase.instance.database;
    final nowStr = DateTime.now().toIso8601String();

    final id = await db.insert('products', {
      'barcode': request.barcode.trim(),
      'product_name': request.productName.trim(),
      'product_batch': request.productBatch.trim(),
      'description': request.description?.trim(),
      'cost_price': request.costPrice,
      'selling_price': request.sellingPrice,
      'qty_cartons': request.cartons,
      'in_stock': request.qtyCartons,
      'supplier_id': request.supplierId,
      'category_id': request.categoryId,
      'mft_date': request.mftDate.trim(),
      'expiry_date': request.expiryDate.trim(),
      'status': (request.qtyCartons > 0) ? 'In Stock' : 'Out of Stock',
      'image_url': request.imageUrl?.trim(),
      'created_at': nowStr,
      'updated_at': nowStr,
    });

    return getProductById(id);
  }

  Future<void> deleteProduct(int id) async {
    final db = await MobileAppDatabase.instance.database;
    final count = await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count == 0) {
      throw Exception('Product not found');
    }
  }

  Future<ProductDetail> updateProduct(
    int id,
    UpdateProductRequest request,
  ) async {
    final db = await MobileAppDatabase.instance.database;
    final nowStr = DateTime.now().toIso8601String();

    final count = await db.update(
      'products',
      {
        'product_name': request.productName.trim(),
        'product_batch': request.productBatch.trim(),
        'description': request.description?.trim(),
        'cost_price': request.costPrice,
        'selling_price': request.sellingPrice,
        'qty_cartons': request.cartons,
        'in_stock': request.qtyCartons,
        'supplier_id': request.supplierId,
        'category_id': request.categoryId,
        'mft_date': request.mftDate.trim(),
        'expiry_date': request.expiryDate.trim(),
        'status': (request.qtyCartons > 0) ? 'In Stock' : 'Out of Stock',
        'image_url': request.imageUrl?.trim(),
        'updated_at': nowStr,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count == 0) {
      throw Exception('Product not found');
    }

    return getProductById(id);
  }

  Future<List<SupplierOption>> getSupplierOptions() async {
    final db = await MobileAppDatabase.instance.database;
    final rows = await db.query(
      'suppliers',
      where: "LOWER(status) = 'active'",
      orderBy: 'supplier_name ASC',
    );

    return rows.map((r) {
      return SupplierOption(
        id: r['id'] as int? ?? 0,
        supplierName: r['supplier_name'] as String? ?? '',
      );
    }).toList();
  }

  Future<List<CategoryOption>> getCategoryOptions() async {
    final db = await MobileAppDatabase.instance.database;
    final rows = await db.query(
      'categories',
      where: "LOWER(status) = 'active'",
      orderBy: 'name ASC',
    );

    return rows.map((r) {
      return CategoryOption(
        id: r['id'] as int? ?? 0,
        name: r['name'] as String? ?? '',
      );
    }).toList();
  }
}
