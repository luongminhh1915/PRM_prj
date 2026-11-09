import 'package:flutter/material.dart';
import 'package:supermarket_manager_system/data/services/customer_api_service.dart';
import 'package:supermarket_manager_system/dto/customer_dto.dart';
import 'package:supermarket_manager_system/dto/order_dto.dart';
import 'package:supermarket_manager_system/mappers/customer_mapper.dart';
import 'package:supermarket_manager_system/models/order_list_item.dart';

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
  String _sortBy = 'spend'; // 'spend', 'points', 'name'

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
      final dtos = list.map(CustomerMapper.fromModel).toList();
      _sortCustomers(dtos);

      setState(() {
        _customers = dtos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _sortCustomers(List<CustomerDto> list) {
    if (_sortBy == 'spend') {
      list.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    } else if (_sortBy == 'points') {
      list.sort((a, b) => b.points.compareTo(a.points));
    } else if (_sortBy == 'name') {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
  }

  List<CustomerDto> get _filteredCustomers {
    final query = _searchController.text.trim().toLowerCase();
    List<CustomerDto> list = _customers;
    if (query.isNotEmpty) {
      list = _customers.where((customer) {
        return customer.name.toLowerCase().contains(query) ||
            customer.phone.toLowerCase().contains(query);
      }).toList();
    }
    _sortCustomers(list);
    return list;
  }

  String _getMemberRank(double totalSpend, int points) {
    if (totalSpend >= 10000000 || points >= 1000) return 'KIM CƯƠNG 💎';
    if (totalSpend >= 5000000 || points >= 500) return 'VÀNG 🥇';
    if (totalSpend >= 2000000 || points >= 200) return 'BẠC 🥈';
    return 'ĐỒNG 🥉';
  }

  Color _getRankColor(String rank) {
    if (rank.contains('KIM CƯƠNG')) return Colors.purple;
    if (rank.contains('VÀNG')) return Colors.amber.shade800;
    if (rank.contains('BẠC')) return Colors.blueGrey;
    return Colors.brown;
  }

  void _showAddOrEditCustomerDialog([CustomerDto? customer]) {
    final nameCtrl = TextEditingController(text: customer?.name ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    final amountCtrl = TextEditingController(
        text: customer != null ? customer.totalAmount.toStringAsFixed(0) : '0');
    String? dialogError;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(customer == null ? 'Thêm Khách Hàng Thân Thiết' : 'Sửa Khách Hàng ${customer.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dialogError != null) ...[
                      Text(dialogError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên khách hàng *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tổng tiền tích lũy chi tiêu (VNĐ)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameCtrl.text.trim();
                          final phone = phoneCtrl.text.trim();
                          final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;

                          if (name.isEmpty || phone.isEmpty) {
                            setDialogState(() => dialogError = 'Vui lòng nhập tên và số điện thoại');
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                            dialogError = null;
                          });

                          try {
                            if (customer == null) {
                              await _apiService.createCustomer(
                                name: name,
                                phone: phone,
                                totalAmount: amount,
                              );
                            } else {
                              await _apiService.updateCustomer(
                                customerId: customer.id,
                                name: name,
                                phone: phone,
                                totalAmount: amount,
                              );
                            }

                            if (dialogCtx.mounted) {
                              Navigator.of(dialogCtx).pop();
                              _loadCustomers();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(customer == null ? 'Thêm khách hàng thành công!' : 'Cập nhật thành công!')),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                              dialogError = e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(customer == null ? 'Thêm mới' : 'Cập nhật'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCustomerHistoryDialog(CustomerDto customer) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.history, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(child: Text('Lịch sử mua hàng: ${customer.name}')),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: FutureBuilder<List<OrderListItem>>(
              future: _apiService.getCustomerOrderHistory(customer.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return const Center(child: Text('Chưa có lịch sử mua hàng nào'));
                }

                return ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final ord = orders[index];
                    return ListTile(
                      title: Text('Mã HD: ${ord.orderNo}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Ngày: ${ord.orderDateTime} • Thu ngân: ${ord.cashierName}'),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${ord.payable.toStringAsFixed(0)}đ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          Chip(
                            label: Text(ord.status, style: const TextStyle(fontSize: 10)),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
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
        title: const Text('Quản Lý Khách Hàng Thân Thiết'),
        actions: [
          IconButton(
            onPressed: _loadCustomers,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditCustomerDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm khách hàng'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Tìm kiếm khách hàng theo tên, SĐT...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.sort),
                  items: const [
                    DropdownMenuItem(value: 'spend', child: Text('BXH Chi tiêu')),
                    DropdownMenuItem(value: 'points', child: Text('BXH Điểm tích lũy')),
                    DropdownMenuItem(value: 'name', child: Text('Sắp xếp theo Tên')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _sortBy = val);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(child: Center(child: Text(_error!)))
            else if (_filteredCustomers.isEmpty)
              const Expanded(child: Center(child: Text('Không tìm thấy khách hàng nào')))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _filteredCustomers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final customer = _filteredCustomers[index];
                    final rankText = _getMemberRank(customer.totalAmount, customer.points);
                    final rankColor = _getRankColor(rankText);

                    Widget rankBadge;
                    if (index == 0 && _sortBy != 'name') {
                      rankBadge = const Text('🥇 #1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
                    } else if (index == 1 && _sortBy != 'name') {
                      rankBadge = const Text('🥈 #2', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
                    } else if (index == 2 && _sortBy != 'name') {
                      rankBadge = const Text('🥉 #3', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
                    } else {
                      rankBadge = Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey));
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: rankColor.withOpacity(0.15),
                        child: Text(
                          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                          style: TextStyle(color: rankColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Row(
                        children: [
                          rankBadge,
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              customer.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: rankColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: rankColor.withOpacity(0.5)),
                            ),
                            child: Text(
                              rankText,
                              style: TextStyle(color: rankColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text('SĐT: ${customer.phone} • Tích điểm: ${customer.points} pts'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${customer.totalAmount.toStringAsFixed(0)}đ',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                              Text('${customer.totalPurchases} đơn hàng', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'edit') {
                                _showAddOrEditCustomerDialog(customer);
                              } else if (val == 'history') {
                                _showCustomerHistoryDialog(customer);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'history',
                                child: Row(
                                  children: [
                                    Icon(Icons.history, size: 18),
                                    SizedBox(width: 8),
                                    Text('Xem lịch sử mua hàng'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text('Sửa thông tin'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () => _showCustomerHistoryDialog(customer),
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
