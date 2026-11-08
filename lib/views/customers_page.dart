import 'package:flutter/material.dart';
import 'package:supermarket_manager_system/data/services/customer_api_service.dart';
import 'package:supermarket_manager_system/dto/customer_dto.dart';
import 'package:supermarket_manager_system/mappers/customer_mapper.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final CustomerApiService _apiService = CustomerApiService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<CustomerDto> _customers = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final list = await _apiService.getCustomers();
      setState(() {
        _customers = list.map(CustomerMapper.fromModel).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<CustomerDto> get _filteredCustomers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _customers;

    return _customers.where((customer) {
      return customer.name.toLowerCase().contains(query) ||
          customer.phone.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            onPressed: _loadCustomers,
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
                prefixIcon: Icon(Icons.search),
                hintText: 'Search customer...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(child: Center(child: Text(_error!)))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _filteredCustomers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final customer = _filteredCustomers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(customer.name.isNotEmpty ? customer.name[0] : 'C'),
                      ),
                      title: Text(customer.name),
                      subtitle: Text(customer.phone),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${customer.totalAmount.toStringAsFixed(0)}đ'),
                          Text('${customer.points} pts'),
                        ],
                      ),
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
