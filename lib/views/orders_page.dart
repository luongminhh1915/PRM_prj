import 'package:flutter/material.dart';
import 'package:supermarket_manager_system/data/services/order_api_service.dart';
import 'package:supermarket_manager_system/dto/order_dto.dart';
import 'package:supermarket_manager_system/mappers/order_mapper.dart';
import 'package:supermarket_manager_system/models/order_detail.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final OrderApiService _apiService = OrderApiService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<OrderDto> _orders = const [];
  String _selectedStatusFilter = 'ALL'; // 'ALL', 'PAID', 'PENDING'

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final list = await _apiService.getOrders();
      setState(() {
        _orders = list.map(OrderMapper.fromModel).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  double _getCalculatedBalance(OrderDto order) {
    if (order.paid == null) return 0.0;
    final bal = order.payable - order.paid!;
    return bal > 0 ? bal : 0.0;
  }

  List<OrderDto> get _filteredOrders {
    final query = _searchController.text.trim().toLowerCase();
    return _orders.where((order) {
      final matchesQuery = query.isEmpty ||
          order.orderNo.toLowerCase().contains(query) ||
          order.customerName.toLowerCase().contains(query) ||
          order.customerPhone.toLowerCase().contains(query);

      final statusUpper = order.status.toUpperCase();
      final balance = _getCalculatedBalance(order);
      bool matchesStatus = true;
      if (_selectedStatusFilter == 'PAID') {
        matchesStatus = statusUpper == 'PAID' && balance <= 0;
      } else if (_selectedStatusFilter == 'PENDING') {
        matchesStatus = statusUpper == 'PENDING' || statusUpper == 'DEBT' || balance > 0;
      }

      return matchesQuery && matchesStatus;
    }).toList();
  }

  void _showReceiptDialog(int orderId) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16),
          title: const Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.blue),
              SizedBox(width: 8),
              Text('Biên Lai Hóa Đơn'),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: FutureBuilder<OrderDetail>(
              future: _apiService.getOrderDetail(orderId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return SizedBox(
                    height: 150,
                    child: Center(child: Text('Lỗi: ${snapshot.error}')),
                  );
                }

                final detail = snapshot.data;
                if (detail == null) {
                  return const SizedBox(
                    height: 150,
                    child: Center(child: Text('Không tìm thấy biên lai')),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'SIÊU THỊ SUPERMARKET',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text('Mã hóa đơn: ${detail.orderNo}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            Text('Thu ngân: ${detail.cashierName}'),
                          ],
                        ),
                      ),
                      const Divider(height: 24),
                      Text('SĐT khách hàng: ${detail.customerPhone}'),
                      const Divider(height: 24),
                      const Text('DANH SÁCH MẶT HÀNG:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...detail.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text('${item.qty} x ${item.unitPrice.toStringAsFixed(0)}đ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Text('${item.amount.toStringAsFixed(0)}đ', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tạm tính:'),
                          Text('${detail.subtotal.toStringAsFixed(0)}đ'),
                        ],
                      ),
                      if (detail.discountPercent > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Giảm giá (${detail.discountPercent.toStringAsFixed(0)}%):'),
                            Text('-${detail.discountAmount.toStringAsFixed(0)}đ', style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('${detail.totalPayment.toStringAsFixed(0)}đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Đơn Hàng Siêu Thị'),
        actions: [
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Tìm theo mã HD, tên khách hàng, SĐT...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Filter Chips
            Row(
              children: [
                FilterChip(
                  label: const Text('Tất cả đơn'),
                  selected: _selectedStatusFilter == 'ALL',
                  onSelected: (_) => setState(() => _selectedStatusFilter = 'ALL'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Đã thanh toán (Paid)'),
                  selected: _selectedStatusFilter == 'PAID',
                  onSelected: (_) => setState(() => _selectedStatusFilter = 'PAID'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Ghi nợ (Pending / Debt)'),
                  selected: _selectedStatusFilter == 'PENDING',
                  onSelected: (_) => setState(() => _selectedStatusFilter = 'PENDING'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(child: Center(child: Text(_error!)))
            else if (_filteredOrders.isEmpty)
              const Expanded(child: Center(child: Text('Không tìm thấy hóa đơn nào')))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _filteredOrders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final order = _filteredOrders[index];
                    final balance = _getCalculatedBalance(order);
                    final isPaid = order.status.toUpperCase() == 'PAID' && balance <= 0;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPaid ? Colors.green.shade100 : Colors.orange.shade100,
                        child: Icon(
                          isPaid ? Icons.check_circle_outline : Icons.pending_actions,
                          color: isPaid ? Colors.green.shade800 : Colors.orange.shade800,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(order.orderNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              isPaid ? 'PAID' : 'GHI NỢ',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isPaid ? Colors.green.shade900 : Colors.red.shade900,
                              ),
                            ),
                            backgroundColor: isPaid ? Colors.green.shade100 : Colors.red.shade100,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      subtitle: Text('${order.customerName} • ${order.customerPhone}\nNgày: ${order.orderDateTime}'),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${order.payable.toStringAsFixed(0)}đ',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue),
                          ),
                          if (balance > 0)
                            Text(
                              'Nợ: ${balance.toStringAsFixed(0)}đ',
                              style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      onTap: () => _showReceiptDialog(order.id),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
