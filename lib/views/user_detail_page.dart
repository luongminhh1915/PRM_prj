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
    _future = _viewModel.getUserDetail(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee detail')),
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
            return const Center(child: Text('Employee not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      child: Text(user.fullname.isNotEmpty ? user.fullname[0] : 'U'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullname,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(user.role),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _InfoRow(title: 'Email', value: user.email),
                _InfoRow(title: 'Username', value: user.username),
                _InfoRow(title: 'Phone', value: user.phone),
                _InfoRow(title: 'Address', value: user.address),
                _InfoRow(title: 'ID card', value: user.idCard),
                _InfoRow(title: 'Status', value: user.status),
                const SizedBox(height: 16),
                const Text(
                  'Shift history',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (user.schedule.isEmpty)
                  const Text('No shift history')
                else
                  ...user.schedule.map(
                    (item) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item.day),
                        subtitle: Text('${item.loginTime} → ${item.logoutTime}'),
                        trailing: Text(item.shiftRevenue),
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
            width: 110,
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value.isEmpty ? '—' : value)),
        ],
      ),
    );
  }
}
