import 'package:flutter/material.dart';
import 'package:supermarket_manager_system/models/order_detail.dart';

class OrderDetailCard extends StatelessWidget {
  const OrderDetailCard({
    super.key,
    required this.detail,
    required this.moneyFormatter,
    this.onBack,
  });

  final OrderDetail detail;
  final String Function(double value) moneyFormatter;
  final VoidCallback? onBack;

  String _discountText() {
    if (detail.discountPercent <= 0 || detail.discountAmount <= 0) {
      return '0đ';
    }
    return '${detail.discountPercent.toStringAsFixed(0)}% (${moneyFormatter(detail.discountAmount)})';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8EAED)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (onBack != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0D9488),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                'Order Detail - ${detail.orderNo}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Text(
                'Số điện thoại khách hàng (nếu có): ${detail.customerPhone}',
                style: const TextStyle(fontSize: 16, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 8),
              Text(
                'Nhân viên bán hàng: ${detail.cashierName}',
                style: const TextStyle(fontSize: 16, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: const WidgetStatePropertyAll(Color(0xFFF7F8FA)),
                  columns: const [
                    DataColumn(label: Text('ĐƠN GIÁ')),
                    DataColumn(label: Text('SỐ LƯỢNG')),
                    DataColumn(label: Text('THÀNH TIỀN')),
                  ],
                  rows: detail.items
                      .map(
                        (item) => DataRow(
                          cells: [
                            DataCell(
                              Text('(${item.productName} - ${moneyFormatter(item.unitPrice)})'),
                            ),
                            DataCell(Text(item.qty.toString())),
                            DataCell(Text(moneyFormatter(item.amount))),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFE8EAED), thickness: 1.5),
              const SizedBox(height: 8),
              _SummaryRow(label: 'Tổng tiền hàng', value: moneyFormatter(detail.subtotal)),
              _SummaryRow(label: 'Giảm giá', value: _discountText()),
              const Divider(color: Color(0xFFE8EAED)),
              _SummaryRow(
                label: 'Tổng thanh toán',
                value: moneyFormatter(detail.totalPayment),
                isTotal: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final style = isTotal
        ? const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Color(0xFF1A1D21))
        : const TextStyle(fontSize: 16, color: Color(0xFF374151));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
