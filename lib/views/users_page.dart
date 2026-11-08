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
          user.email.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            onPressed: () => _viewModel.loadUsers(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search employee...',
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
            else
              Expanded(
                child: ListView.separated(
                  itemCount: filteredUsers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.fullname.isNotEmpty ? user.fullname[0] : 'U'),
                      ),
                      title: Text(user.fullname),
                      subtitle: Text('${user.username} • ${user.email}'),
                      trailing: Chip(
                        label: Text(user.status),
                        backgroundColor: user.status.toLowerCase() == 'active'
                            ? Colors.green.shade100
                            : Colors.red.shade100,
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
