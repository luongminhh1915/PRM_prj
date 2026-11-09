import 'package:flutter/material.dart';
import 'package:supermarket_manager_system/dto/user_dto.dart';
import 'package:supermarket_manager_system/viewmodels/user_viewmodel.dart';
import 'user_detail_page.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final UserViewModel _viewModel = UserViewModel();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.loadUsers();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<UserDto> get filteredUsers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _viewModel.users;
    }

    return _viewModel.users.where((user) {
      return user.fullname.toLowerCase().contains(query) ||
          user.username.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.role.toLowerCase().contains(query);
    }).toList();
  }

  void _showAddUserDialog() {
    final fullnameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final idCardCtrl = TextEditingController();
    String selectedRole = 'CASHIER';
    String? dialogError;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Thêm Nhân Sự Mới'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dialogError != null) ...[
                      Text(
                        dialogError!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: fullnameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: usernameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tên đăng nhập (Username) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Phân quyền vai trò *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ADMIN', child: Text('Admin (Quản trị viên)')),
                        DropdownMenuItem(value: 'MANAGER', child: Text('Manager (Quản lý)')),
                        DropdownMenuItem(value: 'CASHIER', child: Text('Cashier (Thu ngân)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: idCardCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Số CCCD / ID Card',
                        border: OutlineInputBorder(),
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
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final fullname = fullnameCtrl.text.trim();
                          final username = usernameCtrl.text.trim();
                          final email = emailCtrl.text.trim();
                          final password = passwordCtrl.text.trim();

                          if (fullname.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty) {
                            setDialogState(() => dialogError = 'Vui lòng nhập đầy đủ các trường bắt buộc (*)');
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                            dialogError = null;
                          });

                          try {
                            await _viewModel.createUser(
                              fullname: fullname,
                              username: username,
                              email: email,
                              password: password,
                              userRole: selectedRole,
                              idCard: idCardCtrl.text.trim(),
                            );
                            if (dialogCtx.mounted) {
                              Navigator.of(dialogCtx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Thêm nhân viên thành công!')),
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
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Tạo nhân viên'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangeRoleDialog(UserDto user) {
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
                  const Text('Chọn vai trò mới trong hệ thống:'),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    title: const Text('Admin (Quản trị hệ thống)'),
                    value: 'ADMIN',
                    groupValue: currentRole,
                    onChanged: (val) => setDialogState(() => currentRole = val!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Manager (Quản lý cửa hàng)'),
                    value: 'MANAGER',
                    groupValue: currentRole,
                    onChanged: (val) => setDialogState(() => currentRole = val!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Cashier (Thu ngân tại quầy)'),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Cập nhật vai trò ${user.fullname} thành $currentRole thành công!')),
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

  Future<void> _toggleUserStatus(UserDto user) async {
    final isCurrentlyActive = user.status.toLowerCase() == 'active';
    final newStatus = isCurrentlyActive ? 'deactive' : 'active';
    final actionText = isCurrentlyActive ? 'Khóa tài khoản' : 'Kích hoạt tài khoản';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text('$actionText ${user.fullname}?'),
          content: Text(
            isCurrentlyActive
                ? 'Khi bị khóa, tài khoản này sẽ không thể đăng nhập vào hệ thống.'
                : 'Tài khoản sẽ được mở khóa và có thể đăng nhập bình thường.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrentlyActive ? Colors.red : Colors.green,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(actionText, style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _viewModel.updateUserStatus(user.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã $actionText ${user.fullname} thành công!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Nhân Viên'),
        actions: [
          IconButton(
            onPressed: () => _viewModel.loadUsers(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại danh sách',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm nhân viên'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm nhân viên theo tên, username, email...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_viewModel.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_viewModel.errorMessage != null)
              Expanded(
                child: Center(
                  child: Text(_viewModel.errorMessage!),
                ),
              )
            else if (filteredUsers.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('Không tìm thấy nhân viên nào.'),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: filteredUsers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final isActive = user.status.toLowerCase() == 'active';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isActive ? Colors.blue.shade100 : Colors.grey.shade300,
                        child: Text(
                          user.fullname.isNotEmpty ? user.fullname[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: isActive ? Colors.blue.shade900 : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            user.fullname,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              user.role.toUpperCase(),
                              style: const TextStyle(fontSize: 10, color: Colors.white),
                            ),
                            backgroundColor: user.role.toUpperCase() == 'ADMIN'
                                ? Colors.red.shade700
                                : user.role.toUpperCase() == 'MANAGER'
                                    ? Colors.blue.shade700
                                    : Colors.green.shade700,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      subtitle: Text('${user.username} • ${user.email}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isActive ? Icons.lock_open : Icons.lock,
                              color: isActive ? Colors.green : Colors.red,
                            ),
                            tooltip: isActive ? 'Khóa tài khoản' : 'Mở khóa tài khoản',
                            onPressed: () => _toggleUserStatus(user),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'role') {
                                _showChangeRoleDialog(user);
                              } else if (value == 'status') {
                                _toggleUserStatus(user);
                              } else if (value == 'detail') {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => UserDetailPage(userId: user.id),
                                  ),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'detail',
                                child: Row(
                                  children: [
                                    Icon(Icons.person, size: 18),
                                    SizedBox(width: 8),
                                    Text('Xem chi tiết hồ sơ'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'role',
                                child: Row(
                                  children: [
                                    Icon(Icons.admin_panel_settings, size: 18),
                                    SizedBox(width: 8),
                                    Text('Phân quyền vai trò'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'status',
                                child: Row(
                                  children: [
                                    Icon(isActive ? Icons.block : Icons.check_circle, size: 18),
                                    const SizedBox(width: 8),
                                    Text(isActive ? 'Khóa tài khoản' : 'Kích hoạt tài khoản'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => UserDetailPage(userId: user.id),
                          ),
                        );
                      },
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
