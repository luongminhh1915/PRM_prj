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
      body: Center(
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
      ),
    );
  }
}
