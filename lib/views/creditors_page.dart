import 'package:flutter/material.dart';
import 'package:supermarket_manager_system/data/local/mobile_app_database.dart';
import 'package:supermarket_manager_system/dto/order_dto.dart';

class CreditorsPage extends StatefulWidget {
  const CreditorsPage({super.key});

  @override
  State<CreditorsPage> createState() => _CreditorsPageState();
}

class _CreditorsPageState extends State<CreditorsPage> {
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
          status: totalDebt > 0 ? 'Outstanding' : 'Paid',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creditors'),
        actions: [
          IconButton(
            onPressed: _loadDebts,
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
                  itemCount: _debts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final debt = _debts[index];
                    return ListTile(
                      title: Text(debt.customerName),
                      subtitle: Text(debt.customerPhone),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${debt.totalDebt.toStringAsFixed(0)}đ'),
                          Text(
                            debt.status,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
