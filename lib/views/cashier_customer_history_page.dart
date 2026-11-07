import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supermarket_manager_system/data/services/order_api_service.dart';
import 'package:supermarket_manager_system/models/order_list_item.dart';
import 'package:supermarket_manager_system/utils/app_session.dart';

class CashierCustomerHistoryPage extends StatefulWidget {
  const CashierCustomerHistoryPage({
    super.key,
    required this.fullName,
    required this.phone,
  });

  final String fullName;
  final String phone;

  @override
  State<CashierCustomerHistoryPage> createState() => _CashierCustomerHistoryPageState();
}

class _CashierCustomerHistoryPageState extends State<CashierCustomerHistoryPage> {
  late DateTime _now;
  Timer? _clockTimer;
  final TextEditingController _totalCashEndController = TextEditingController();
  final _orderApiService = OrderApiService();
  bool _isLoading = true;
  String? _error;
  List<OrderListItem> _orders = const [];

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
    _loadHistory();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _totalCashEndController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final allOrders = await _orderApiService.getOrders();
      final filtered = allOrders
          .where((o) => o.customerPhone.trim() == widget.phone.trim())
          .toList();
      if (!mounted) {
        return;
      }
      setState(() {
        _orders = filtered;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _timeText() =>
      '${_two(_now.hour)}:${_two(_now.minute)}:${_two(_now.second)}';

  String _two(int n) => n.toString().padLeft(2, '0');

  String _money(double amount) => '${amount.toStringAsFixed(0)}đ';

  String _discountText(double p) => p <= 0 ? '—' : p.toStringAsFixed(0);

  Future<void> _openCloseShiftDialog() async {
    final fullName = widget.fullName.isEmpty ? 'Cashier' : widget.fullName;
    _totalCashEndController.clear();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Close Shift',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Employee name'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(fullName),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _totalCashEndController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Enter total cash after shift',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElevatedButton(
                    onPressed: () {
                      final amount = double.tryParse(
                        _totalCashEndController.text.trim().replaceAll(',', ''),
                      );
                      if (amount == null || amount < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid total cash amount.')),
                        );
                        return;
                      }
                      Navigator.of(dialogContext).pop();
                      AppSession.instance.clear();
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                    child: const Text('Confirm & close shift', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = widget.fullName.isEmpty ? 'Cashier' : widget.fullName;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Row(
        children: [
          Container(
            width: 240,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  color: const Color.fromRGBO(0, 0, 0, 0.12),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Text('P', style: TextStyle(color: Color(0xFF667EEA))),
                      ),
                      SizedBox(width: 10),
                      Text('SMS SYSTEM', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _CashierMenuItem(
                  label: 'Barcode Scanner',
                  active: false,
                  onTap: () => context.go('/cashier/barcode-scanner'),
                ),
                _CashierMenuItem(
                  label: 'Customer',
                  active: true,
                  onTap: () => context.go('/cashier/customers'),
                ),
                const Spacer(),
                _CashierMenuItem(label: 'Logout', active: false, onTap: _openCloseShiftDialog),
                const SizedBox(height: 10),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFE8EAED))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_timeText(), style: const TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 14),
                      Text(fullName),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextButton.icon(
                          onPressed: () => context.go('/cashier/customers'),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to Customer List'),
                          style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Customer Order History - ${widget.phone.isEmpty ? '—' : widget.phone}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _error != null
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Cannot load history: $_error'),
                                          const SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed: _loadHistory,
                                            child: const Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE8EAED)),
                                      ),
                                      child: _orders.isEmpty
                                          ? const Center(
                                              child: Padding(
                                                padding: EdgeInsets.all(24),
                                                child: Text(
                                                  'No orders found for this phone number.',
                                                ),
                                              ),
                                            )
                                          : SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: DataTable(
                                                columns: const [
                                                  DataColumn(label: Text('ORDER ID')),
                                                  DataColumn(label: Text('DATE/TIME')),
                                                  DataColumn(label: Text('TOTAL')),
                                                  DataColumn(label: Text('DISCOUNT (%)')),
                                                  DataColumn(label: Text('PAYABLE')),
                                                  DataColumn(label: Text('PAYMENT')),
                                                  DataColumn(label: Text('STATUS')),
                                                  DataColumn(label: Text('ACTION')),
                                                ],
                                                rows: _orders
                                                    .map(
                                                      (o) => DataRow(
                                                        cells: [
                                                          DataCell(Text(o.orderNo)),
                                                          DataCell(Text(o.orderDateTime)),
                                                          DataCell(Text(_money(o.total))),
                                                          DataCell(Text(_discountText(o.discountPercent))),
                                                          DataCell(Text(_money(o.payable))),
                                                          DataCell(Text(o.paymentMethod)),
                                                          DataCell(Text(o.status)),
                                                          DataCell(
                                                            TextButton(
                                                              onPressed: () {
                                                                ScaffoldMessenger.of(context)
                                                                    .showSnackBar(
                                                                  const SnackBar(
                                                                    content: Text(
                                                                      'Order detail view will be added next.',
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                              child: const Text('View'),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                            ),
                                    ),
                        ),
                      ],
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
}

class _CashierMenuItem extends StatelessWidget {
  const _CashierMenuItem({
    required this.label,
    required this.active,
    this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color.fromRGBO(255, 255, 255, 0.2) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

