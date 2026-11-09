import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supermarket_manager_system/utils/app_session.dart';
import 'package:supermarket_manager_system/views/dashboard_content.dart';
import 'package:supermarket_manager_system/views/revenue_report_page.dart';
import 'package:supermarket_manager_system/views/suppliers_page.dart';
import 'package:supermarket_manager_system/views/profile_content_page.dart';
import 'package:supermarket_manager_system/views/users_page.dart';
import 'package:supermarket_manager_system/views/customers_page.dart';
import 'package:supermarket_manager_system/views/orders_page.dart';
import 'package:supermarket_manager_system/views/creditors_page.dart';
import 'package:supermarket_manager_system/models/user_detail.dart';

class ManagerDashboardPage extends StatefulWidget {
  const ManagerDashboardPage({
    super.key,
    required this.fullName,
    required this.userId,
    this.initialTab = 'dashboard',
  });

  final String fullName;
  final int userId;
  final String initialTab;

  @override
  State<ManagerDashboardPage> createState() => _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends State<ManagerDashboardPage> {
  late String _currentTab;
  bool _editingProfile = false;
  UserDetail? _editingUserDetail;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  void _onTabSelected(String tabKey) {
    setState(() {
      _currentTab = tabKey;
      _editingProfile = false;
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Đăng Xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi hệ thống Manager?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Đăng Xuất', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      AppSession.instance.clear();
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 900;
    final now = DateTime.now();
    final timeText = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      key: _scaffoldKey,
      drawer: isCompact ? _buildSidebar(isDrawer: true) : null,
      body: Row(
        children: [
          if (!isCompact) _buildSidebar(isDrawer: false),
          Expanded(
            child: Stack(
              children: [
                _buildActiveTabContent(isCompact, timeText),
                if (isCompact)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: SafeArea(
                      child: Material(
                        color: Colors.white,
                        elevation: 2,
                        borderRadius: BorderRadius.circular(8),
                        child: IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                        ),
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

  Widget _buildSidebar({required bool isDrawer}) {
    return Container(
      width: 250,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          // Header Logo
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Siêu Thị Manager',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Quản Lý Siêu Thị',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _sidebarItem(
                  key: 'dashboard',
                  label: 'Tổng Quan KPI',
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                ),
                _sidebarItem(
                  key: 'reports',
                  label: 'Báo Cáo Doanh Thu',
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart,
                ),
                _sidebarItem(
                  key: 'users',
                  label: 'Quản Lý Nhân Viên',
                  icon: Icons.people_alt_outlined,
                  activeIcon: Icons.people_alt,
                ),
                _sidebarItem(
                  key: 'customers',
                  label: 'Khách Hàng Thân Thiết',
                  icon: Icons.group_outlined,
                  activeIcon: Icons.group,
                ),
                _sidebarItem(
                  key: 'orders',
                  label: 'Quản Lý Đơn Hàng',
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                ),
                _sidebarItem(
                  key: 'creditors',
                  label: 'Sổ Nợ / Công Nợ',
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet,
                ),
                _sidebarItem(
                  key: 'suppliers',
                  label: 'Nhà Cung Cấp',
                  icon: Icons.local_shipping_outlined,
                  activeIcon: Icons.local_shipping,
                ),
                _sidebarItem(
                  key: 'profile',
                  label: 'Hồ Sơ Cá Nhân',
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                ),
              ],
            ),
          ),

          // User Footer
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF3B82F6),
                  child: Text(
                    widget.fullName.isNotEmpty ? widget.fullName[0].toUpperCase() : 'M',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.fullName.isEmpty ? 'Manager' : widget.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const Text(
                        'Vai trò: Manager',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 20),
                  onPressed: _logout,
                  tooltip: 'Đăng xuất',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem({
    required String key,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isSelected = _currentTab == key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            _onTabSelected(key);
            if (_scaffoldKey.currentState?.isDrawerOpen == true) {
              Navigator.of(context).pop();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(bool isCompact, String timeText) {
    switch (_currentTab) {
      case 'dashboard':
        return DashboardContent(
          fullName: widget.fullName,
          roleLabel: 'Manager',
          isCompact: isCompact,
          currentTimeText: timeText,
          onNavigatePath: (path) {},
        );
      case 'reports':
        return RevenueReportPage(
          fullName: widget.fullName,
          isCompact: isCompact,
          currentTimeText: timeText,
        );
      case 'users':
        return const UsersPage();
      case 'customers':
        return const CustomersPage();
      case 'orders':
        return const OrdersPage();
      case 'creditors':
        return const CreditorsPage();
      case 'suppliers':
        return SuppliersPage(
          fullName: widget.fullName,
          isCompact: isCompact,
          currentTimeText: timeText,
        );
      case 'profile':
        if (_editingProfile) {
          return ProfileEditContent(
            userId: widget.userId,
            initialDetail: _editingUserDetail,
            isCompact: isCompact,
            currentTimeText: timeText,
            onSaved: (detail) {
              setState(() {
                _editingUserDetail = detail;
                _editingProfile = false;
              });
            },
            onCancel: () {
              setState(() => _editingProfile = false);
            },
          );
        }
        return ProfileViewContent(
          fullName: widget.fullName,
          userId: widget.userId,
          isCompact: isCompact,
          currentTimeText: timeText,
          onEditProfile: (detail) {
            setState(() {
              _editingUserDetail = detail;
              _editingProfile = true;
            });
          },
        );
      default:
        return Center(child: Text('Nội dung màn hình $_currentTab'));
    }
  }
}
