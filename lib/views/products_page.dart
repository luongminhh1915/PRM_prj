import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supermarket_manager_system/models/product_list_item.dart';
import 'package:supermarket_manager_system/viewmodels/product_viewmodel.dart';
import 'package:supermarket_manager_system/views/widgets/dashboard_header.dart';
import 'package:supermarket_manager_system/views/widgets/update_product_dialog.dart';

class ProductsContent extends ConsumerStatefulWidget {
  const ProductsContent({
    super.key,
    required this.fullName,
    required this.isCompact,
    required this.currentTimeText,
    required this.onProfileTap,
  });

  final String fullName;
  final bool isCompact;
  final String currentTimeText;
  final VoidCallback onProfileTap;

  @override
  ConsumerState<ProductsContent> createState() => _ProductsContentState();
}

class _ProductsContentState extends ConsumerState<ProductsContent> {
  late Future<List<ProductListItem>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _reloadProducts();
  }

  void _reloadProducts() {
    setState(() {
      _productsFuture = ref.read(productViewModelProvider.notifier).loadProducts().then(
            (_) => ref.read(productViewModelProvider).products,
          );
    });
  }

  Future<void> _confirmDeleteProduct(int productId, String productName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteConfirmDialog(productName: productName),
    );

    if (confirmed == true) {
      await _deleteProduct(productId);
    }
  }

  Future<void> _deleteProduct(int productId) async {
    try {
      await ref.read(productViewModelProvider.notifier).deleteProduct(productId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _reloadProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showUpdateDialog(int productId) async {
    try {
      final productDetail = await ref
          .read(productViewModelProvider.notifier)
          .getProductById(productId);
      if (!mounted) return;

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => UpdateProductDialog(product: productDetail),
      );

      if (!mounted) return;

      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _reloadProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F7FC),
      child: Column(
        children: [
          _ProductsHeader(
            fullName: widget.fullName,
            isCompact: widget.isCompact,
            currentTimeText: widget.currentTimeText,
            onProfileTap: widget.onProfileTap,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(widget.isCompact ? 14 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  widget.isCompact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Stock Inventory',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _actionButton(
                                  label: '+ Add New Product',
                                  backgroundColor: const Color(0xFF2563EB),
                                  textColor: Colors.white,
                                  onPressed: () async {
                                    final result = await context.push(
                                      '${_basePathFromLocation(context)}/add-product',
                                    );
                                    if (result == true) {
                                      _reloadProducts();
                                    }
                                  },
                                  compact: true,
                                ),
                                const SizedBox(height: 8),
                                _actionButton(
                                  label: 'Import Product',
                                  backgroundColor: Colors.white,
                                  textColor: const Color(0xFF1E40AF),
                                  onPressed: () {},
                                  compact: true,
                                  borderColor: const Color(0xFFD6E3F8),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Stock Inventory',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Row(
                              children: [
                                _actionButton(
                                  label: 'Import Product',
                                  backgroundColor: Colors.white,
                                  textColor: const Color(0xFF1E40AF),
                                  onPressed: () {},
                                  borderColor: const Color(0xFFD6E3F8),
                                ),
                                const SizedBox(width: 8),
                                _actionButton(
                                  label: '+ Add New Product',
                                  backgroundColor: const Color(0xFF2563EB),
                                  textColor: Colors.white,
                                  onPressed: () async {
                                    final result = await context.push(
                                      '${_basePathFromLocation(context)}/add-product',
                                    );
                                    if (result == true) {
                                      _reloadProducts();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                  SizedBox(height: widget.isCompact ? 12 : 20),
                  Expanded(
                    child: FutureBuilder<List<ProductListItem>>(
                      future: _productsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Cannot load products: ${snapshot.error}',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _reloadProducts,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        }

                        final products = snapshot.data ?? [];
                        if (products.isEmpty) {
                          return const Center(child: Text('No products found'));
                        }

                        if (widget.isCompact) {
                          return ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: products.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return _buildMobileProductCard(product);
                            },
                          );
                        }

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE3EAF6)),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              horizontalMargin: 16,
                              columnSpacing: 16,
                              headingRowColor: const WidgetStatePropertyAll(
                                Color(0xFFF7F8FA),
                              ),
                              headingTextStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4A5568),
                                fontSize: 12,
                              ),
                              columns: const [
                                DataColumn(
                                  label: SizedBox(
                                    width: 110,
                                    child: Text('BARCODE'),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 120,
                                    child: Text('PRODUCTS'),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 100,
                                    child: Text('CATEGORY'),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 110,
                                    child: Text('EXPIRE'),
                                  ),
                                ),
                                DataColumn(
                                  numeric: true,
                                  label: SizedBox(
                                    width: 90,
                                    child: Text('PRICE'),
                                  ),
                                ),
                                DataColumn(
                                  numeric: true,
                                  label: SizedBox(
                                    width: 80,
                                    child: Text('IN STOCK'),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 110,
                                    child: Text('STATUS'),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 200,
                                    child: Text('ACTIONS'),
                                  ),
                                ),
                              ],
                              rows: products.map(_buildRow).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildRow(ProductListItem product) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 110,
            child: InkWell(
              onTap: product.id <= 0
                  ? null
                  : () => context.push(
                      '${_basePathFromLocation(context)}/products/detail/${product.id}',
                    ),
              child: Text(
                product.barcode.isEmpty ? '-' : product.barcode,
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 120,
            child: Text(
              product.productName.isEmpty ? '-' : product.productName,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 100,
            child: Text(
              product.categoryName.isEmpty ? '-' : product.categoryName,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 110,
            child: Text(
              product.expiryDate.isEmpty ? '-' : product.expiryDate,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 90,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(product.sellingPrice.toStringAsFixed(2)),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 80,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(product.inStock.toString()),
            ),
          ),
        ),
        DataCell(
          SizedBox(width: 110, child: _StatusBadge(status: product.status)),
        ),
        DataCell(
          SizedBox(
            width: 200,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () => _showUpdateDialog(product.id),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    foregroundColor: const Color(0xFF667EEA),
                    side: const BorderSide(color: Color(0xFF667EEA)),
                  ),
                  child: const Text('Edit'),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: () =>
                      _confirmDeleteProduct(product.id, product.productName),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
    Color? borderColor,
    bool compact = false,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        color: backgroundColor,
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 10 : 12,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: compact ? 12 : 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileProductCard(ProductListItem product) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7ECF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10213A63),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF4FF),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  product.productName.isEmpty
                      ? '?'
                      : product.productName[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName.isEmpty ? '-' : product.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: product.id <= 0
                          ? null
                          : () => context.push(
                              '${_basePathFromLocation(context)}/products/detail/${product.id}',
                            ),
                      child: Text(
                        product.barcode.isEmpty ? '-' : product.barcode,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: product.status),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ProductMetricChip(
                label: 'Category',
                value: product.categoryName.isEmpty ? '-' : product.categoryName,
              ),
              _ProductMetricChip(
                label: 'Price',
                value: product.sellingPrice.toStringAsFixed(2),
              ),
              _ProductMetricChip(label: 'In Stock', value: '${product.inStock}'),
              _ProductMetricChip(
                label: 'Expire',
                value: product.expiryDate.isEmpty ? '-' : product.expiryDate,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showUpdateDialog(product.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E40AF),
                    side: const BorderSide(color: Color(0xFFD6E3F8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _confirmDeleteProduct(product.id, product.productName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _basePathFromLocation(BuildContext context) {
  final loc = GoRouterState.of(context).uri.path;
  if (loc.startsWith('/manager')) return '/manager';
  return '/admin';
}

class _ProductsHeader extends StatelessWidget {
  const _ProductsHeader({
    required this.fullName,
    required this.isCompact,
    required this.currentTimeText,
    required this.onProfileTap,
  });

  final String fullName;
  final bool isCompact;
  final String currentTimeText;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return DashboardHeader(
      fullName: fullName,
      roleLabel: 'Manager',
      currentTimeText: currentTimeText,
      isCompact: isCompact,
      onProfileTap: onProfileTap,
      timeChipColor: const Color(0xFF3B82F6),
      avatarColor: const Color(0xFF1E293B),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final isInStock = normalized.contains('in');
    final bg = isInStock ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2);
    final fg = isInStock ? const Color(0xFF065F46) : const Color(0xFF991B1B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: bg,
      ),
      child: Text(
        status.isEmpty ? '-' : status,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog({required this.productName});

  final String productName;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Confirm Delete',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to delete this product?',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            if (productName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Product: $productName',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF374151)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductMetricChip extends StatelessWidget {
  const _ProductMetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EBF8)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Color(0xFF111827)),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
