import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supermarket_manager_system/viewmodels/order_viewmodel.dart';
import 'package:supermarket_manager_system/views/widgets/dashboard_header.dart';
import 'package:supermarket_manager_system/models/dashboard_summary.dart';

class DashboardContent extends ConsumerStatefulWidget {
  const DashboardContent({
    super.key,
    required this.fullName,
    required this.roleLabel,
    required this.isCompact,
    required this.currentTimeText,
    this.onNavigatePath,
  });

  final String fullName;
  final String roleLabel;
  final bool isCompact;
  final String currentTimeText;
  final ValueChanged<String>? onNavigatePath;

  @override
  ConsumerState<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends ConsumerState<DashboardContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardViewModelProvider.notifier).loadDashboard();
    });
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} ₫';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardViewModelProvider);
    final notifier = ref.read(dashboardViewModelProvider.notifier);

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          DashboardHeader(
            title: 'Tổng Quan Chỉ Số Kinh Doanh (KPI)',
            fullName: widget.fullName,
            roleLabel: widget.roleLabel,
            currentTimeText: widget.currentTimeText,
            isCompact: widget.isCompact,
            timeChipColor: const Color(0xFF4ECDC4),
            avatarColor: const Color(0xFF1E293B),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(60),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.errorMessage != null)
                    _buildErrorCard(state.errorMessage!, notifier)
                  else if (state.summary != null) ...[
                    _buildTopStatsGrid(state.summary!),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 900;
                        if (!isWide) {
                          return Column(
                            children: [
                              _buildTopProductsCard(state.summary!.topProducts),
                              const SizedBox(height: 24),
                              _buildAlertsCard(state.summary!),
                              const SizedBox(height: 24),
                              _buildRecentTransactionsCard(state),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: Column(
                                children: [
                                  _buildTopProductsCard(state.summary!.topProducts),
                                  const SizedBox(height: 24),
                                  _buildRecentTransactionsCard(state),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 4,
                              child: Column(
                                children: [
                                  _buildAlertsCard(state.summary!),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStatsGrid(DashboardSummary summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final crossCount = isMobile ? 2 : 4;
        final width = (constraints.maxWidth - (16 * (crossCount - 1))) / crossCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _StatCard(
              width: width,
              title: 'Doanh Số Hôm Nay',
              value: _formatCurrency(summary.todaySales),
              subtitle: '${summary.todayInvoiceCount} đơn hàng hôm nay',
              icon: Icons.monetization_on_outlined,
              iconColor: const Color(0xFF16A34A),
              bgColor: const Color(0xFFF0FDF4),
            ),
            _StatCard(
              width: width,
              title: 'Doanh Thu Tháng Này',
              value: _formatCurrency(summary.currentMonthSales),
              subtitle: 'Doanh thu tích lũy tháng',
              icon: Icons.trending_up_rounded,
              iconColor: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
            ),
            _StatCard(
              width: width,
              title: 'Hàng Sắp Hết / Hết Hạn',
              value: '${summary.expiredProducts} sản phẩm',
              subtitle: 'Cần kiểm tra kho ngay',
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFDC2626),
              bgColor: const Color(0xFFFEF2F2),
            ),
            _StatCard(
              width: width,
              title: 'Tổng Nhà Cung Cấp',
              value: '${summary.supplierCount} đối tác',
              subtitle: 'Đang hợp tác',
              icon: Icons.local_shipping_outlined,
              iconColor: const Color(0xFF9333EA),
              bgColor: const Color(0xFFFAF5FF),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopProductsCard(List<TopProduct> topProducts) {
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
            children: const [
              Icon(Icons.star_rounded, color: Color(0xFFEAB308)),
              SizedBox(width: 8),
              Text(
                'Top Sản Phẩm Bán Chạy',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (topProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('Chưa có dữ liệu bán hàng')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topProducts.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final p = topProducts[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: index == 0
                              ? const Color(0xFFFEF3C7)
                              : index == 1
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFFFFEDD5),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '#${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: index == 0
                                ? const Color(0xFFD97706)
                                : index == 1
                                    ? const Color(0xFF475569)
                                    : const Color(0xFFC2410C),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Đã bán: ${p.totalQty}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAlertsCard(DashboardSummary summary) {
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
            children: const [
              Icon(Icons.notifications_active_outlined, color: Color(0xFFDC2626)),
              SizedBox(width: 8),
              Text(
                'Cảnh Báo Hệ Thống',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _alertItem(
            title: 'Sản phẩm hết hạn / sắp hết hạn',
            description: 'Có ${summary.expiredProducts} sản phẩm cần xử lý hủy hoặc giảm giá.',
            icon: Icons.error_outline,
            color: const Color(0xFFDC2626),
            bgColor: const Color(0xFFFEF2F2),
          ),
          const SizedBox(height: 12),
          _alertItem(
            title: 'Khách hàng mới tăng trưởng',
            description: 'Đã phát sinh ${summary.todayInvoiceCount} đơn trong ngày hôm nay.',
            icon: Icons.check_circle_outline,
            color: const Color(0xFF16A34A),
            bgColor: const Color(0xFFF0FDF4),
          ),
          const SizedBox(height: 12),
          _alertItem(
            title: 'Nhà cung cấp hoạt động',
            description: 'Tổng cộng ${summary.supplierCount} đối tác nhà phân phối trong hệ thống.',
            icon: Icons.local_shipping_outlined,
            color: const Color(0xFF2563EB),
            bgColor: const Color(0xFFEFF6FF),
          ),
        ],
      ),
    );
  }

  Widget _alertItem({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsCard(DashboardState state) {
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
            'Giao Dịch Gần Đây Trong Ngày',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          if (state.todayTransactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('Chưa có giao dịch trong ngày hôm nay')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.todayTransactions.length.clamp(0, 5),
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final tx = state.todayTransactions[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFF1F5F9),
                    child: Icon(
                      tx.paymentMethod == 'Cash'
                          ? Icons.money
                          : Icons.account_balance_wallet,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  title: Text(
                    tx.orderNo,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('${tx.customerName} • ${tx.orderTime}'),
                  trailing: Text(
                    _formatCurrency(tx.totalPayable),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error, DashboardViewModel notifier) {
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
            onPressed: () => notifier.loadDashboard(),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  final double width;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
