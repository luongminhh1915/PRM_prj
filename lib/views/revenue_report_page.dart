import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supermarket_manager_system/viewmodels/report_viewmodel.dart';
import 'package:supermarket_manager_system/views/widgets/dashboard_header.dart';

class RevenueReportPage extends ConsumerStatefulWidget {
  const RevenueReportPage({
    super.key,
    required this.fullName,
    required this.isCompact,
    required this.currentTimeText,
  });

  final String fullName;
  final bool isCompact;
  final String currentTimeText;

  @override
  ConsumerState<RevenueReportPage> createState() => _RevenueReportPageState();
}

class _RevenueReportPageState extends ConsumerState<RevenueReportPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportViewModelProvider.notifier).loadReport();
    });
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} ₫';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportViewModelProvider);
    final notifier = ref.read(reportViewModelProvider.notifier);

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          DashboardHeader(
            title: 'Báo Cáo Doanh Thu & Tài Chính',
            fullName: widget.fullName,
            roleLabel: 'Báo Cáo',
            currentTimeText: widget.currentTimeText,
            isCompact: widget.isCompact,
            timeChipColor: const Color(0xFF0EA5E9),
            avatarColor: const Color(0xFF0F172A),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter bar
                  _buildFilterBar(context, state, notifier),
                  const SizedBox(height: 20),

                  if (state.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(60),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.errorMessage != null)
                    _buildErrorCard(state.errorMessage!, notifier)
                  else ...[
                    // KPI summary cards
                    _buildKpiCards(state),
                    const SizedBox(height: 24),

                    // Revenue Chart Card
                    _buildChartCard(state),
                    const SizedBox(height: 24),

                    // Revenue Table Card
                    _buildTableCard(state),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    ReportState state,
    ReportViewModel notifier,
  ) {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => currentYear - i);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_outlined, color: Color(0xFF475569)),
          const SizedBox(width: 10),
          const Text(
            'Bộ Lọc:',
            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
          const SizedBox(width: 16),
          // Year Picker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: state.selectedYear,
                items: years.map((y) {
                  return DropdownMenuItem<int>(
                    value: y,
                    child: Text('Năm $y', style: const TextStyle(fontWeight: FontWeight.w600)),
                  );
                }).toList(),
                onChanged: (y) {
                  if (y != null) notifier.changeYear(y);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Month Picker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: state.selectedMonth,
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Cả Năm (12 tháng)', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  ...List.generate(12, (i) => i + 1).map((m) {
                    return DropdownMenuItem<int?>(
                      value: m,
                      child: Text('Tháng $m', style: const TextStyle(fontWeight: FontWeight.w600)),
                    );
                  }),
                ],
                onChanged: (m) => notifier.changeMonth(m),
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => notifier.loadReport(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Tải lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCards(ReportState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final crossCount = isMobile ? 2 : 4;
        final width = (constraints.maxWidth - (16 * (crossCount - 1))) / crossCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _KpiCard(
              width: width,
              title: 'Tổng Doanh Thu',
              value: _formatCurrency(state.totalRevenue),
              icon: Icons.payments_outlined,
              color: const Color(0xFF2563EB),
              bgGradient: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
            ),
            _KpiCard(
              width: width,
              title: 'Doanh Số Tiền Mặt',
              value: _formatCurrency(state.cashRevenue),
              icon: Icons.money_sharp,
              color: const Color(0xFF16A34A),
              bgGradient: const [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
            ),
            _KpiCard(
              width: width,
              title: 'Chuyển Khoản / Thẻ',
              value: _formatCurrency(state.transferRevenue),
              icon: Icons.account_balance_outlined,
              color: const Color(0xFF9333EA),
              bgGradient: const [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
            ),
            _KpiCard(
              width: width,
              title: 'Tổng Đơn Hàng',
              value: '${state.totalOrders} đơn',
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFFEA580C),
              bgGradient: const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartCard(ReportState state) {
    final maxVal = state.items.fold<double>(
      0,
      (max, e) => e.totalRevenue > max ? e.totalRevenue : max,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.selectedMonth != null
                        ? 'Biểu Đồ Doanh Thu Tháng ${state.selectedMonth}/${state.selectedYear}'
                        : 'Biểu Đồ Doanh Thu 12 Tháng Năm ${state.selectedYear}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Phân tích tổng hợp doanh thu tiền mặt & chuyển khoản theo thời gian',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Row(
                children: [
                  _chartLegendItem('Tiền mặt', const Color(0xFF16A34A)),
                  const SizedBox(width: 12),
                  _chartLegendItem('Chuyển khoản/Thẻ', const Color(0xFF9333EA)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: state.items.isEmpty
                ? const Center(child: Text('Không có dữ liệu doanh thu'))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = constraints.maxWidth / state.items.length;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: state.items.map((item) {
                          final heightPct = maxVal > 0 ? (item.totalRevenue / maxVal) : 0.0;
                          final cashPct = item.totalRevenue > 0
                              ? (item.cashRevenue / item.totalRevenue)
                              : 0.0;

                          return SizedBox(
                            width: itemWidth,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (item.totalRevenue > 0)
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${(item.totalRevenue / 1000).toStringAsFixed(0)}k',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Container(
                                  width: (itemWidth * 0.55).clamp(8, 28).toDouble(),
                                  height: (200 * heightPct).clamp(4, 200).toDouble(),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          flex: ((1 - cashPct) * 100).toInt(),
                                          child: Container(color: const Color(0xFF9333EA)),
                                        ),
                                        Expanded(
                                          flex: (cashPct * 100).toInt(),
                                          child: Container(color: const Color(0xFF16A34A)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chartLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
        ),
      ],
    );
  }

  Widget _buildTableCard(ReportState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          const Text(
            'Chi Tiết Dữ Liệu Báo Cáo',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columns: const [
                DataColumn(label: Text('Thời Gian', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Số Đơn Hàng', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Doanh Số Tiền Mặt', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Chuyển Khoản / Thẻ', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Tổng Doanh Thu', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('TB / Đơn', style: TextStyle(fontWeight: FontWeight.w700))),
              ],
              rows: state.items.map((item) {
                final avg = item.orderCount > 0 ? item.totalRevenue / item.orderCount : 0.0;
                return DataRow(
                  cells: [
                    DataCell(Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text('${item.orderCount}')),
                    DataCell(Text(_formatCurrency(item.cashRevenue), style: const TextStyle(color: Color(0xFF16A34A)))),
                    DataCell(Text(_formatCurrency(item.transferRevenue), style: const TextStyle(color: Color(0xFF9333EA)))),
                    DataCell(Text(_formatCurrency(item.totalRevenue), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B)))),
                    DataCell(Text(_formatCurrency(avg))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error, ReportViewModel notifier) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 40),
          const SizedBox(height: 12),
          Text(error, style: const TextStyle(color: Color(0xFFB91C1C))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => notifier.loadReport(),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgGradient,
  });

  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final List<Color> bgGradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: bgGradient),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color,
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
