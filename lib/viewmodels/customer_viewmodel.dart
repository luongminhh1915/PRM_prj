import 'package:flutter_riverpod/legacy.dart';
import 'package:supermarket_manager_system/data/services/customer_api_service.dart';
import 'package:supermarket_manager_system/models/customer_detail.dart';
import 'package:supermarket_manager_system/models/customer_list_item.dart';
import 'package:supermarket_manager_system/models/order_list_item.dart';

class CustomerState {
  final bool isLoading;
  final List<CustomerListItem> customers;
  final List<CustomerListItem> filteredCustomers;
  final String searchQuery;
  final String? errorMessage;

  const CustomerState({
    this.isLoading = false,
    this.customers = const [],
    this.filteredCustomers = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  CustomerState copyWith({
    bool? isLoading,
    List<CustomerListItem>? customers,
    List<CustomerListItem>? filteredCustomers,
    String? searchQuery,
    String? errorMessage,
  }) {
    return CustomerState(
      isLoading: isLoading ?? this.isLoading,
      customers: customers ?? this.customers,
      filteredCustomers: filteredCustomers ?? this.filteredCustomers,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}

class CustomerViewModel extends StateNotifier<CustomerState> {
  final CustomerApiService _apiService;

  CustomerViewModel({CustomerApiService? apiService})
      : _apiService = apiService ?? CustomerApiService(),
        super(const CustomerState());

  Future<void> loadCustomers() async {
    await Future<void>.delayed(Duration.zero);
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _apiService.getCustomers();
      state = state.copyWith(
        isLoading: false,
        customers: list,
        filteredCustomers: _applyFilter(list, state.searchQuery),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void search(String query) {
    final clean = query.trim().toLowerCase();
    state = state.copyWith(
      searchQuery: clean,
      filteredCustomers: _applyFilter(state.customers, clean),
    );
  }

  List<CustomerListItem> _applyFilter(
    List<CustomerListItem> items,
    String query,
  ) {
    if (query.isEmpty) return items;
    return items.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.phone.toLowerCase().contains(query);
    }).toList();
  }

  Future<CustomerDetail> getCustomerDetail(int id) async {
    return _apiService.getCustomerDetail(id);
  }

  Future<CustomerListItem> getCustomerByPhone(String phone) async {
    return _apiService.getCustomerByPhone(phone);
  }

  Future<CustomerListItem> createCustomer({
    required String name,
    required String phone,
    double? totalAmount,
  }) async {
    final customer = await _apiService.createCustomer(
      name: name,
      phone: phone,
      totalAmount: totalAmount,
    );
    await loadCustomers();
    return customer;
  }

  Future<CustomerListItem> updateCustomer({
    required int customerId,
    required String name,
    required String phone,
    double? totalAmount,
  }) async {
    final customer = await _apiService.updateCustomer(
      customerId: customerId,
      name: name,
      phone: phone,
      totalAmount: totalAmount,
    );
    await loadCustomers();
    return customer;
  }

  Future<List<OrderListItem>> getCustomerOrderHistory(int customerId) async {
    return _apiService.getCustomerOrderHistory(customerId);
  }
}

final customerViewModelProvider =
    StateNotifierProvider<CustomerViewModel, CustomerState>((ref) {
  return CustomerViewModel();
});

