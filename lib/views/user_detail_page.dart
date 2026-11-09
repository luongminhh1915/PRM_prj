import 'package:flutter/material.dart';
import 'package:supermarket_manager_system/dto/user_dto.dart';
import 'package:supermarket_manager_system/viewmodels/user_viewmodel.dart';

class UserDetailPage extends StatefulWidget {
  const UserDetailPage({super.key, required this.userId});

  final int userId;

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  final UserViewModel _viewModel = UserViewModel();
  late Future<UserDetailDto> _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = _viewModel.getUserDetail(widget.userId);
    });
  }

  Future<void> _toggleStatus(UserDetailDto user) async {
    final isActive = user.status.toLowerCase() == 'active';
    final newStatus = isActive ? 'deactive' : 'active';
    await _viewModel.updateUserStatus(user.id, newStatus);
    _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã ${isActive ? "khóa" : "mở khóa"} tài khoản ${user.fullname}')),
      );
    }
  }

  void _showChangeRoleDialog(UserDetailDto user) {
    String currentRole = user.role.toUpperCase();
    if (!['ADMIN', 'MANAGER', 'CASHIER'].contains(currentRole)) {
      currentRole = 'CASHIER';
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Phân quyền cho ${user.fullname}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Admin (Quản trị viên)'),
                    value: 'ADMIN',
                    groupValue: currentRole,
                    onChanged: (val) => setDialogState(() => currentRole = val!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Manager (Quản lý)'),
                    value: 'MANAGER',
                    groupValue: currentRole,
                    onChanged: (val) => setDialogState(() => currentRole = val!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Cashier (Thu ngân)'),
                    value: 'CASHIER',
                    groupValue: currentRole,
                    onChanged: (val) => setDialogState(() => currentRole = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _viewModel.updateUserRole(user.id, currentRole);
                    if (dialogCtx.mounted) {
                      Navigator.of(dialogCtx).pop();
                      _refresh();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã đổi vai trò thành $currentRole')),
                      );
                    }
                  },
                  child: const Text('Lưu vai trò'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ Sơ Nhân Viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: FutureBuilder<UserDetailDto>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('Không tìm thấy thông tin nhân viên'));
          }

          final isActive = user.status.toLowerCase() == 'active';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: isActive ? Colors.blue.shade100 : Colors.grey.shade300,
                          child: Text(
                            user.fullname.isNotEmpty ? user.fullname[0].toUpperCase() : 'U',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.blue.shade900 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullname,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Chip(
                                    label: Text(
                                      user.role.toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontSize: 11),
                                    ),
                                    backgroundColor: user.role.toUpperCase() == 'ADMIN'
                                        ? Colors.red.shade700
                                        : user.role.toUpperCase() == 'MANAGER'
                                            ? Colors.blue.shade700
                                            : Colors.green.shade700,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const SizedBox(width: 8),
                                  Chip(
                                    label: Text(
                                      isActive ? 'HOẠT ĐỘNG' : 'ĐÃ KHÓA',
                                      style: TextStyle(
                                        color: isActive ? Colors.green.shade900 : Colors.red.shade900,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor: isActive ? Colors.green.shade100 : Colors.red.shade100,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showChangeRoleDialog(user),
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text('Phân quyền vai trò'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isActive ? Colors.red : Colors.green,
                        ),
                        onPressed: () => _toggleStatus(user),
                        icon: Icon(isActive ? Icons.lock : Icons.lock_open),
                        label: Text(isActive ? 'Khóa tài khoản' : 'Mở khóa'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  'Thông tin liên hệ & Hệ thống',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoRow(title: 'Tên tài khoản', value: user.username),
                        _InfoRow(title: 'Email liên hệ', value: user.email),
                        _InfoRow(title: 'Số điện thoại', value: user.phone),
                        _InfoRow(title: 'Địa chỉ cư trú', value: user.address),
                        _InfoRow(title: 'Số CCCD / ID Card', value: user.idCard),
                        _InfoRow(title: 'Đăng nhập gần nhất', value: user.lastLogin),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Lịch sử ca làm việc gần đây',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (user.schedule.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('Chưa có lịch sử ca làm việc nào ghi nhận')),
                  )
                else
                  ...user.schedule.map(
                    (item) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.access_time_filled, color: Colors.blue),
                        title: Text('Ca làm ngày: ${item.day}'),
                        subtitle: Text('Thời gian: ${item.loginTime} → ${item.logoutTime}'),
                        trailing: Text(
                          'Doanh số: ${item.shiftRevenue}đ',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
