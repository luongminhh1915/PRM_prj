import 'package:flutter/material.dart';
import 'package:supermarket_manager_system/data/services/order_api_service.dart';
import 'package:supermarket_manager_system/dto/order_dto.dart';
import 'package:supermarket_manager_system/mappers/order_mapper.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final OrderApiService _apiService = OrderApiService();
  bool _isLoading = true;
  String? _error;
  List<OrderDto> _orders = const [];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales orders'),
        actions: [
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return ListTile(
                      title: Text(order.orderNo),
                      subtitle: Text('${order.customerName} • ${order.customerPhone}'),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${order.payable.toStringAsFixed(0)}đ'),
                          Chip(
                            label: Text(order.status),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
