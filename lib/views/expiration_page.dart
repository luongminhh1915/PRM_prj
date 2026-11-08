import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supermarket_manager_system/views/widgets/dashboard_header.dart';
import 'package:go_router/go_router.dart';
import 'package:supermarket_manager_system/data/services/expiration_api_service.dart';
import 'package:supermarket_manager_system/data/services/product_api_service.dart';
import 'package:supermarket_manager_system/models/expiration_product.dart';
import 'package:supermarket_manager_system/models/expiration_stats.dart';

class ExpirationContent extends StatefulWidget {
  const ExpirationContent({
    super.key,
    required this.fullName,
    required this.isCompact,
    required this.currentTimeText,
    required this.onProfileTap,
    this.onProductDetailTap,
  });

  final String fullName;
  final bool isCompact;
  final String currentTimeText;
  final VoidCallback onProfileTap;
  final ValueChanged<int>? onProductDetailTap;

  @override
  State<ExpirationContent> createState() => _ExpirationContentState();
}

class _ExpirationContentState extends State<ExpirationContent> {
  final _expirationApiService = ExpirationApiService();
  final _productApiService = ProductApiService();

  late Future<ExpirationStats> _statsFuture;
  late Future<List<ExpirationProduct>> _productsFuture;
  String _selectedFilter = 'today';

  @override
  void initState() {
    super.initState();
    _statsFuture = _expirationApiService.getExpirationStats();
    _productsFuture = _expirationApiService.getProductsExpiringToday();
  }

  void _changeFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      switch (filter) {
        case 'today':
          _productsFuture = _expirationApiService.getProductsExpiringToday();
          break;
        case '7days':
          _productsFuture = _expirationApiService.getProductsExpiringIn7Days();
          break;
        case '3months':
          _productsFuture = _expirationApiService
              .getProductsExpiringIn3Months();
          break;
        case '6months':
          _productsFuture = _expirationApiService
              .getProductsExpiringIn6Months();
          break;
      }
    });
  }

  void _reloadData() {
    setState(() {
      _statsFuture = _expirationApiService.getExpirationStats();
      _changeFilter(_selectedFilter);
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
      await _productApiService.deleteProduct(productId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _reloadData();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F7FC),
      child: Column(
        children: [
          _ExpirationHeader(
            fullName: widget.fullName,
            isCompact: widget.isCompact,
            currentTimeText: widget.currentTimeText,
            onProfileTap: widget.onProfileTap,
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    widget.isCompact ? 14 : 24,
                    widget.isCompact ? 14 : 24,
                    widget.isCompact ? 14 : 24,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Expiration Notification',
                        style: TextStyle(
                          fontSize: widget.isCompact ? 20 : 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: widget.isCompact ? 12 : 20),
                      FutureBuilder<ExpirationStats>(
                        future: _statsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }
                          final stats =
                              snapshot.data ??
                              const ExpirationStats(
                                expiresToday: 0,
                                expiresIn7Days: 0,
                                expiresIn3Months: 0,
                                expiresIn6Months: 0,
                              );
                          return _buildStatsCards(stats);
                        },
                      ),
                      SizedBox(height: widget.isCompact ? 18 : 32),
                      Text(
                        'Expiration Details',
                        style: TextStyle(
                          fontSize: widget.isCompact ? 18 : 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: widget.isCompact ? 12 : 20),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      widget.isCompact ? 14 : 24,
                      0,
                      widget.isCompact ? 14 : 24,
                      widget.isCompact ? 14 : 24,
                    ),
                    child: FutureBuilder<List<ExpirationProduct>>(
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
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        final products = snapshot.data ?? [];
                        if (products.isEmpty) {
                          return const Center(child: Text('No products found'));
                        }
                        return widget.isCompact
                            ? _buildProductsMobileList(products)
                            : _buildProductsTable(products);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(ExpirationStats stats) {
    final cards = [
      _StatCard(
        icon: '🛒',
        title: 'Expires Today',
        count: stats.expiresToday,
        isSelected: _selectedFilter == 'today',
        onTap: () => _changeFilter('today'),
        compact: widget.isCompact,
      ),
      _StatCard(
        icon: '⭐',
        title: 'Expires in 7 Days',
        count: stats.expiresIn7Days,
        isSelected: _selectedFilter == '7days',
        onTap: () => _changeFilter('7days'),
        compact: widget.isCompact,
      ),
      _StatCard(
        icon: '🔄',
        title: 'Expires In 3 Month Time',
        count: stats.expiresIn3Months,
        isSelected: _selectedFilter == '3months',
        onTap: () => _changeFilter('3months'),
        compact: widget.isCompact,
      ),
      _StatCard(
        icon: '✓',
        title: 'Expires in 6 Month',
        count: stats.expiresIn6Months,
        isSelected: _selectedFilter == '6months',
        onTap: () => _changeFilter('6months'),
        compact: widget.isCompact,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!widget.isCompact) {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
              const SizedBox(width: 16),
              Expanded(child: cards[2]),
              const SizedBox(width: 16),
              Expanded(child: cards[3]),
            ],
          );
        }

        const spacing = 10.0;
        final cardWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((card) => SizedBox(width: cardWidth, child: card))
              .toList(),
        );
      },
    );
  }

  Widget _buildProductsTable(List<ExpirationProduct> products) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
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
                    label: SizedBox(width: 150, child: Text('PRODUCT')),
                  ),
                  DataColumn(
                    label: SizedBox(width: 100, child: Text('STOCK QTY')),
                  ),
                  DataColumn(
                    label: SizedBox(width: 120, child: Text('SUPPLIER')),
                  ),
                  DataColumn(
                    label: SizedBox(width: 110, child: Text('EXPIRY DATE')),
                  ),
                  DataColumn(
                    label: SizedBox(width: 100, child: Text('STATUS')),
                  ),
                  DataColumn(
                    label: SizedBox(width: 140, child: Text('ACTION')),
                  ),
                ],
                rows: products.map((product) => _buildRow(product)).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsMobileList(List<ExpirationProduct> products) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildMobileProductCard(products[index]),
    );
  }

  Widget _buildMobileProductCard(ExpirationProduct product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7ECF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10213A63),
            blurRadius: 18,
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
              Expanded(
                child: Text(
                  product.productName.isEmpty ? '-' : product.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _StatusBadge(status: product.status),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ExpirationInfoChip(
                label: 'Stock',
                value: product.inStock.toString(),
              ),
              _ExpirationInfoChip(
                label: 'Supplier',
                value: product.supplierName.isEmpty ? '-' : product.supplierName,
              ),
              _ExpirationInfoChip(
                label: 'Expiry',
                value: product.expiryDate.isEmpty ? '-' : product.expiryDate,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (widget.onProductDetailTap != null) {
                      widget.onProductDetailTap!(product.id);
                    } else {
                      final basePath = _basePathFromLocation(context);
                      context.push('$basePath/products/detail/${product.id}');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E40AF),
                    side: const BorderSide(color: Color(0xFFD6E3F8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'View',
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

  DataRow _buildRow(ExpirationProduct product) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              product.productName.isEmpty ? '-' : product.productName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(SizedBox(width: 100, child: Text(product.inStock.toString()))),
        DataCell(
          SizedBox(
            width: 120,
            child: Text(
              product.supplierName.isEmpty ? '-' : product.supplierName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 110,
            child: Text(product.expiryDate.isEmpty ? '-' : product.expiryDate),
          ),
        ),
        DataCell(
          SizedBox(width: 100, child: _StatusBadge(status: product.status)),
        ),
        DataCell(
          SizedBox(
            width: 140,
            child: widget.isCompact
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          if (widget.onProductDetailTap != null) {
                            widget.onProductDetailTap!(product.id);
                          } else {
                            final basePath = _basePathFromLocation(context);
                            context.push(
                              '$basePath/products/detail/${product.id}',
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          visualDensity: VisualDensity.compact,
                          foregroundColor: const Color(0xFF667EEA),
                          side: const BorderSide(color: Color(0xFF667EEA)),
                        ),
                        child: const Text('View'),
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton(
                        onPressed: () => _confirmDeleteProduct(
                          product.id,
                          product.productName,
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          visualDensity: VisualDensity.compact,
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          if (widget.onProductDetailTap != null) {
                            widget.onProductDetailTap!(product.id);
                          } else {
                            final basePath = _basePathFromLocation(context);
                            context.push(
                              '$basePath/products/detail/${product.id}',
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          foregroundColor: const Color(0xFF667EEA),
                          side: const BorderSide(color: Color(0xFF667EEA)),
                        ),
                        child: const Text('View'),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton(
                        onPressed: () => _confirmDeleteProduct(
                          product.id,
                          product.productName,
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
}

String _basePathFromLocation(BuildContext context) {
  final loc = GoRouterState.of(context).uri.path;
  if (loc.startsWith('/manager')) return '/manager';
  return '/admin';
}

class _ExpirationHeader extends StatelessWidget {
  const _ExpirationHeader({
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.isSelected,
    required this.onTap,
    required this.compact,
  });

  final String icon;
  final String title;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF667EEA)
                : const Color(0xFFE8EAED),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: TextStyle(fontSize: compact ? 22 : 32)),
                const Spacer(),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: compact ? 28 : 32,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? const Color(0xFF667EEA) : Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 4 : 8),
            Text(
              title,
              style: TextStyle(
                fontSize: compact ? 12 : 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status.toLowerCase()) {
      case 'expired':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        break;
      case 'expires today':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        break;
      case 'soon':
        bg = const Color(0xFFFED7AA);
        fg = const Color(0xFF9A3412);
        break;
      case 'warning':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        break;
      default:
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
    }

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

class _ExpirationInfoChip extends StatelessWidget {
  const _ExpirationInfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
