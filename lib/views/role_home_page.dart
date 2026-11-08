import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supermarket_manager_system/utils/app_session.dart';

class RoleHomePage extends StatefulWidget {
  const RoleHomePage({
    super.key,
    required this.role,
    required this.fullName,
  });

  final String role;
  final String fullName;

  @override
  State<RoleHomePage> createState() => _RoleHomePageState();
}

class _RoleHomePageState extends State<RoleHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectByRole();
    });
  }

  void _redirectByRole() {
    final roleUpper = widget.role.trim().toUpperCase();
    if (roleUpper == 'ADMIN') {
      context.go('/admin/dashboard');
    } else if (roleUpper == 'MANAGER') {
      context.go('/manager/dashboard');
    } else if (roleUpper == 'CASHIER') {
      context.go('/cashier/open-shift');
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    AppSession.instance.clear();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final roleUpper = widget.role.trim().toUpperCase();
    final isRecognizedRole =
        roleUpper == 'ADMIN' || roleUpper == 'MANAGER' || roleUpper == 'CASHIER';

    final menuItems = <_MenuItem>[
      _MenuItem('Users', Icons.people_alt, '/users'),
      _MenuItem('Customers', Icons.group, '/customers'),
      _MenuItem('Orders', Icons.receipt_long, '/orders'),
      _MenuItem('Creditors', Icons.account_balance_wallet, '/creditors'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isRecognizedRole
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Xin chào ${widget.fullName.isEmpty ? 'User' : widget.fullName}\nRole: ${widget.role}\nĐang chuyển hướng...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Welcome ${widget.fullName.isEmpty ? 'User' : widget.fullName}\nRole: ${widget.role}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: menuItems.map((item) {
                        return Card(
                          child: InkWell(
                            onTap: () => context.go(item.route),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(item.icon, size: 38, color: Colors.blue),
                                  const SizedBox(height: 12),
                                  Text(
                                    item.label,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}
