import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supermarket_manager_system/viewmodels/supplier_viewmodel.dart';
import 'package:supermarket_manager_system/models/supplier_list_item.dart';
import 'package:supermarket_manager_system/models/product_list_item.dart';

class SupplierDetailPage extends ConsumerStatefulWidget {
  const SupplierDetailPage({super.key, required this.supplierId});

  final int supplierId;

  @override
  ConsumerState<SupplierDetailPage> createState() => _SupplierDetailPageState();
}

class _SupplierDetailPageState extends ConsumerState<SupplierDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(supplierViewModelProvider.notifier).loadSupplierDetail(widget.supplierId);
    });
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} ₫';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supplierViewModelProvider);
    final detail = state.selectedSupplierDetail;
    final products = state.supplierProducts;

    return Scaffold(
      appBar: AppBar(
        title: Text(detail != null ? 'Chi Tiết: ${detail.supplierName}' : 'Chi Tiết Nhà Cung Cấp'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Builder(
        builder: (context) {
          if (state.isDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.errorMessage!, style: const TextStyle(color: Color(0xFFDC2626))),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.read(supplierViewModelProvider.notifier).loadSupplierDetail(widget.supplierId),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          if (detail == null) {
            return const Center(child: Text('Không tìm thấy thông tin nhà cung cấp'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(detail),
                const SizedBox(height: 24),
                _buildProductsSection(products),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(SupplierListItem detail) {
    final isActive = detail.status.toLowerCase() == 'active';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_shipping_outlined, color: Color(0xFF9333EA), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.supplierName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mã NCC: #${detail.id}',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'Đang hoạt động' : 'Tạm ngưng',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isActive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              Widget item(String label, String value, IconData icon) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: const Color(0xFF64748B)),
                      const SizedBox(width: 10),
                      Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      Expanded(
                        child: Text(
                          value.isEmpty ? '—' : value,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (!isWide) {
                return Column(
                  children: [
                    item('Tên công ty', detail.companyName, Icons.business_outlined),
                    item('Email', detail.email, Icons.email_outlined),
                    item('Số điện thoại', detail.phone, Icons.phone_outlined),
                    item('Địa chỉ', detail.address, Icons.location_on_outlined),
                    item('Ngày hợp tác', detail.createdAt ?? '—', Icons.calendar_today_outlined),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: item('Tên công ty', detail.companyName, Icons.business_outlined)),
                      Expanded(child: item('Email', detail.email, Icons.email_outlined)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: item('Số điện thoại', detail.phone, Icons.phone_outlined)),
                      Expanded(child: item('Địa chỉ', detail.address, Icons.location_on_outlined)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: item('Ngày hợp tác', detail.createdAt ?? '—', Icons.calendar_today_outlined)),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(List<ProductListItem> products) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Danh Mục Mặt Hàng Cung Cấp',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Tổng: ${products.length} mặt hàng',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: Text('Chưa có thông tin mặt hàng nhập từ nhà cung cấp này')),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columns: const [
                  DataColumn(label: Text('Mã Vạch', style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(label: Text('Tên Sản Phẩm', style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(label: Text('Danh Mục', style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(label: Text('Giá Bán', style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(label: Text('Tồn Kho', style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(label: Text('Hạn Sử Dụng', style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(label: Text('Trạng Thái', style: TextStyle(fontWeight: FontWeight.w700))),
                ],
                rows: products.map((p) {
                  return DataRow(
                    cells: [
                      DataCell(Text(p.barcode.isEmpty ? '—' : p.barcode)),
                      DataCell(Text(p.productName, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(p.categoryName)),
                      DataCell(Text(_formatCurrency(p.sellingPrice), style: const TextStyle(fontWeight: FontWeight.w700))),
                      DataCell(Text('${p.inStock}')),
                      DataCell(Text(p.expiryDate)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            p.status,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
