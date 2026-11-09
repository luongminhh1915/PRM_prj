import 'package:flutter/material.dart';
import 'package:supermarket_manager_system/data/local/mobile_app_database.dart';
import 'package:supermarket_manager_system/dto/order_dto.dart';

class CreditorsPage extends StatefulWidget {
  const CreditorsPage({super.key});

  @override
  State<CreditorsPage> createState() => _CreditorsPageState();
}

class _CreditorsPageState extends State<CreditorsPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<DebtDto> _debts = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final db = await MobileAppDatabase.instance.database;
      final rows = await db.rawQuery('''
        SELECT c.id AS customer_id,
               c.name AS customer_name,
               c.phone AS customer_phone,
               COALESCE(SUM(o.balance), 0) AS total_debt,
               MAX(o.created_at) AS last_order_at
        FROM customers c
        LEFT JOIN sales_orders o ON o.customer_id = c.id
        GROUP BY c.id, c.name, c.phone
        HAVING COALESCE(SUM(o.balance), 0) > 0
        ORDER BY total_debt DESC
      ''');

      final debts = rows.map((row) {
        final totalDebt = (row['total_debt'] as num?)?.toDouble() ?? 0.0;
        final dateString = row['last_order_at'] as String?;
        return DebtDto(
          customerId: (row['customer_id'] as num?)?.toInt() ?? 0,
          customerName: row['customer_name'] as String? ?? '—',
          customerPhone: row['customer_phone'] as String? ?? '—',
          totalDebt: totalDebt,
          lastOrderAt: dateString != null ? DateTime.tryParse(dateString) : null,
          status: totalDebt > 0 ? 'Còn nợ (Outstanding)' : 'Đã trả (Paid)',
        );
      }).toList();

      setState(() {
        _debts = debts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<DebtDto> get _filteredDebts {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _debts;

    return _debts.where((debt) {
      return debt.customerName.toLowerCase().contains(query) ||
          debt.customerPhone.toLowerCase().contains(query);
    }).toList();
  }

  void _showPayDebtDialog(DebtDto debt) async {
    final amountCtrl = TextEditingController(text: debt.totalDebt.toStringAsFixed(0));
    String? dialogError;
    bool isSubmitting = false;

    final db = await MobileAppDatabase.instance.database;
    final debtOrders = await db.rawQuery(
      '''
      SELECT id, order_no, total_payable, paid, balance, order_date
      FROM sales_orders
      WHERE customer_id = ? AND balance > 0
      ORDER BY id ASC
      ''',
      [debt.customerId],
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Thanh Toán Công Nợ: ${debt.customerName}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SĐT liên hệ: ${debt.customerPhone}'),
                    Text(
                      'Tổng số tiền còn nợ: ${debt.totalDebt.toStringAsFixed(0)}đ',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    const Text('Danh sách hóa đơn ghi nợ chưa trả:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ...debtOrders.map((o) {
                      final bal = (o['balance'] as num?)?.toDouble() ?? 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('• Đơn ${o['order_no']} (${o['order_date']}): còn nợ ${bal.toStringAsFixed(0)}đ'),
                      );
                    }),
                    const SizedBox(height: 16),
                    if (dialogError != null) ...[
                      Text(dialogError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số tiền thanh toán nợ hôm nay (VNĐ) *',
                        border: OutlineInputBorder(),
                        suffixText: 'đ',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final payAmount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                          if (payAmount <= 0) {
                            setDialogState(() => dialogError = 'Vui lòng nhập số tiền hợp lệ lớn hơn 0');
                            return;
                          }
                          if (payAmount > debt.totalDebt) {
                            setDialogState(() => dialogError = 'Số tiền trả vượt quá tổng dư nợ hiện tại');
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                            dialogError = null;
                          });

                          try {
                            double remainingToDeduct = payAmount;
                            final nowStr = DateTime.now().toIso8601String();

                            for (final ord in debtOrders) {
                              if (remainingToDeduct <= 0) break;
                              final ordId = ord['id'] as int;
                              final curBalance = (ord['balance'] as num?)?.toDouble() ?? 0.0;
                              final curPaid = (ord['paid'] as num?)?.toDouble() ?? 0.0;

                              if (curBalance <= 0) continue;

                              final deductThisOrder = remainingToDeduct > curBalance ? curBalance : remainingToDeduct;
                              final newBalance = curBalance - deductThisOrder;
                              final newPaid = curPaid + deductThisOrder;
                              final newStatus = newBalance <= 0 ? 'Paid' : 'Pending';

                              await db.update(
                                'sales_orders',
                                {
                                  'paid': newPaid,
                                  'balance': newBalance,
                                  'status': newStatus,
                                  'updated_at': nowStr,
                                },
                                where: 'id = ?',
                                whereArgs: [ordId],
                              );

                              remainingToDeduct -= deductThisOrder;
                            }

                            if (dialogCtx.mounted) {
                              Navigator.of(dialogCtx).pop();
                              _loadDebts();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Đã gạch nợ thành công ${payAmount.toStringAsFixed(0)}đ cho ${debt.customerName}!')),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              dialogError = e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Xác nhận thu nợ', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
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
        title: const Text('Quản Lý Sổ Nợ / Công Nợ Khách Hàng'),
        actions: [
          IconButton(
            onPressed: _loadDebts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm con nợ theo tên, số điện thoại...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(child: Center(child: Text(_error!)))
            else if (_filteredDebts.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Không có dư nợ công nợ nào chưa thanh toán! 🎉',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _filteredDebts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final debt = _filteredDebts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.shade100,
                        child: Icon(Icons.account_balance_wallet, color: Colors.red.shade900),
                      ),
                      title: Text(
                        debt.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('SĐT: ${debt.customerPhone} • ${debt.status}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${debt.totalDebt.toStringAsFixed(0)}đ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                              const Text('Tổng dư nợ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () => _showPayDebtDialog(debt),
                            icon: const Icon(Icons.payments, size: 16, color: Colors.white),
                            label: const Text('Thu nợ', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                      onTap: () => _showPayDebtDialog(debt),
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
