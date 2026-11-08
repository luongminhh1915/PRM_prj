import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supermarket_manager_system/data/services/product_api_service.dart';
import 'package:supermarket_manager_system/models/product_detail.dart';

class ProductDetailContent extends StatefulWidget {
  const ProductDetailContent({
    super.key,
    required this.productId,
    required this.onBack,
  });

  final int productId;
  final VoidCallback onBack;

  @override
  State<ProductDetailContent> createState() => _ProductDetailContentState();
}

class _ProductDetailContentState extends State<ProductDetailContent> {
  final _productApiService = ProductApiService();
  late Future<ProductDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = _productApiService.getProductById(widget.productId);
  }

  void _reload() {
    setState(() {
      _future = _productApiService.getProductById(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProductDetail>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cannot load product detail: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _reload, child: const Text('Retry')),
              ],
            ),
          );
        }

        final detail = snapshot.data;
        if (detail == null) {
          return const Center(child: Text('No data'));
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextButton.icon(
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                foregroundColor: const Color(0xFF3B82F6),
                padding: EdgeInsets.zero,
              ),
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back, size: 20),
              label: const Text(
                'Back to Stock Inventory',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Product Detail',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _DetailCard(detail: detail),
          ],
        );
      },
    );
  }
}

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    super.key,
    required this.productId,
    required this.basePath,
    required this.fullName,
  });

  final int productId;
  final String basePath;
  final String fullName;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late DateTime _now;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String _formatClock(DateTime dateTime) {
    final hour12 = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute:$second $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 700;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Column(
          children: [
            _DetailHeader(
              fullName: widget.fullName,
              currentTimeText: _formatClock(_now),
              roleLabel: widget.basePath == 'manager'
                  ? 'Manager'
                  : 'Administrator',
              isCompact: isCompact,
            ),
            Expanded(
              child: ProductDetailContent(
                productId: widget.productId,
                onBack: () {
                  final fallbackPath = '/${widget.basePath}/products';
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(fallbackPath);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.fullName,
    required this.currentTimeText,
    required this.roleLabel,
    required this.isCompact,
  });

  final String fullName;
  final String currentTimeText;
  final String roleLabel;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8EAED))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isCompact) const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              currentTimeText,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          if (!isCompact) ...[
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fullName.isEmpty ? roleLabel : fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  roleLabel,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              fullName.isNotEmpty ? fullName[0].toUpperCase() : roleLabel[0],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.detail});

  final ProductDetail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAED)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.06),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;
              final imageWidget = _ProductImage(url: detail.imageUrl);
              final headingWidget = _ProductHeading(
                productName: detail.productName,
                barcode: detail.barcode,
                status: detail.status,
                inStock: detail.inStock,
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    imageWidget,
                    const SizedBox(height: 16),
                    headingWidget,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  imageWidget,
                  const SizedBox(width: 24),
                  Expanded(child: headingWidget),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFE8EAED)),
          _DetailRow(label: 'Barcode', value: _dashIfEmpty(detail.barcode)),
          _DetailRow(
            label: 'Product Batch',
            value: _dashIfEmpty(detail.productBatch),
          ),
          _DetailRow(
            label: 'Product Name',
            value: _dashIfEmpty(detail.productName),
          ),
          _DetailRow(
            label: 'Product Description',
            value: _dashIfEmpty(detail.description),
            isDescription: true,
          ),
          _DetailRow(
            label: 'Cost Price',
            value: detail.costPrice == null
                ? '—'
                : detail.costPrice!.toStringAsFixed(2),
          ),
          _DetailRow(
            label: 'Selling Price',
            value: detail.sellingPrice.toStringAsFixed(2),
          ),
          _DetailRow(
            label: 'Qty (Cartons)',
            value: detail.qtyCartons?.toString() ?? '—',
          ),
          _DetailRow(label: 'In Stock', value: detail.inStock.toString()),
          _DetailRow(
            label: 'Supplier',
            value: _dashIfEmpty(detail.supplierName),
          ),
          _DetailRow(
            label: 'Category',
            value: _dashIfEmpty(detail.categoryName),
          ),
          _DetailRow(label: 'MFT Date', value: _dashIfEmpty(detail.mftDate)),
          _DetailRow(
            label: 'Expiry Date',
            value: _dashIfEmpty(detail.expiryDate),
          ),
        ],
      ),
    );
  }

  static String _dashIfEmpty(String value) =>
      value.trim().isEmpty ? '—' : value;
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url.trim().isNotEmpty;
    final fallback = Container(
      width: 220,
      height: 220,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8EAED), Color(0xFFD1D5DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
      ),
      child: const Text(
        'Product Image',
        style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
      ),
    );

    if (!hasUrl) {
      return fallback;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: 220,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}

class _ProductHeading extends StatelessWidget {
  const _ProductHeading({
    required this.productName,
    required this.barcode,
    required this.status,
    required this.inStock,
  });

  final String productName;
  final String barcode;
  final String status;
  final int inStock;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final computedInStock = inStock > 0;
    final isInStock =
        normalized.contains('in') || (status.trim().isEmpty && computedInStock);
    final badgeBg = isInStock
        ? const Color(0xFFD1FAE5)
        : const Color(0xFFFEE2E2);
    final badgeFg = isInStock
        ? const Color(0xFF065F46)
        : const Color(0xFF991B1B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          productName.trim().isEmpty ? '—' : productName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Barcode: ${barcode.trim().isEmpty ? '—' : barcode}',
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: badgeBg,
          ),
          child: Text(
            status.trim().isEmpty ? '—' : status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: badgeFg,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isDescription = false,
  });

  final String label;
  final String value;
  final bool isDescription;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                fontSize: 14,
                height: isDescription ? 1.35 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
