import 'package:flutter_riverpod/legacy.dart';
import 'package:supermarket_manager_system/data/services/supplier_api_service.dart';
import 'package:supermarket_manager_system/models/supplier_list_item.dart';
import 'package:supermarket_manager_system/models/product_list_item.dart';

class SupplierListState {
  final bool isLoading;
  final List<SupplierListItem> suppliers;
  final List<SupplierListItem> filteredSuppliers;
  final String searchQuery;
  final String statusFilter;
  final SupplierListItem? selectedSupplierDetail;
  final List<ProductListItem> supplierProducts;
  final bool isDetailLoading;
  final String? errorMessage;

  const SupplierListState({
    this.isLoading = false,
    this.suppliers = const [],
    this.filteredSuppliers = const [],
    this.searchQuery = '',
    this.statusFilter = 'All',
    this.selectedSupplierDetail,
    this.supplierProducts = const [],
    this.isDetailLoading = false,
    this.errorMessage,
  });

  SupplierListState copyWith({
    bool? isLoading,
    List<SupplierListItem>? suppliers,
    List<SupplierListItem>? filteredSuppliers,
    String? searchQuery,
    String? statusFilter,
    SupplierListItem? selectedSupplierDetail,
    List<ProductListItem>? supplierProducts,
    bool? isDetailLoading,
    String? errorMessage,
  }) {
    return SupplierListState(
      isLoading: isLoading ?? this.isLoading,
      suppliers: suppliers ?? this.suppliers,
      filteredSuppliers: filteredSuppliers ?? this.filteredSuppliers,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      selectedSupplierDetail: selectedSupplierDetail ?? this.selectedSupplierDetail,
      supplierProducts: supplierProducts ?? this.supplierProducts,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      errorMessage: errorMessage,
    );
  }
}

class SupplierViewModel extends StateNotifier<SupplierListState> {
  final SupplierApiService _apiService;

  SupplierViewModel({SupplierApiService? apiService})
      : _apiService = apiService ?? SupplierApiService(),
        super(const SupplierListState());

  Future<void> loadSuppliers() async {
    await Future<void>.delayed(Duration.zero);
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _apiService.getSuppliers();
      state = state.copyWith(isLoading: false, suppliers: list);
      _applyFilter();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilter();
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
    _applyFilter();
  }

  void _applyFilter() {
    final query = state.searchQuery.trim().toLowerCase();
    final status = state.statusFilter;

    final filtered = state.suppliers.where((s) {
      final matchesQuery = query.isEmpty ||
          s.supplierName.toLowerCase().contains(query) ||
          s.companyName.toLowerCase().contains(query) ||
          s.email.toLowerCase().contains(query) ||
          s.phone.toLowerCase().contains(query);

      final matchesStatus = status == 'All' ||
          s.status.toLowerCase() == status.toLowerCase();

      return matchesQuery && matchesStatus;
    }).toList();

    state = state.copyWith(filteredSuppliers: filtered);
  }

  Future<void> loadSupplierDetail(int id) async {
    state = state.copyWith(isDetailLoading: true, errorMessage: null);
    try {
      final detail = await _apiService.getSupplierById(id);
      final products = await _apiService.getSupplierProducts(id);
      state = state.copyWith(
        isDetailLoading: false,
        selectedSupplierDetail: detail,
        supplierProducts: products,
      );
    } catch (e) {
      state = state.copyWith(
        isDetailLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> createSupplier({
    required String supplierName,
    String? companyName,
    String? email,
    String? phone,
    String? address,
    String? status,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _apiService.createSupplier(
        supplierName: supplierName,
        companyName: companyName,
        email: email,
        phone: phone,
        address: address,
        status: status,
      );
      await loadSuppliers();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> updateSupplier({
    required int id,
    required String supplierName,
    String? companyName,
    String? email,
    String? phone,
    String? address,
    String? status,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _apiService.updateSupplier(
        id: id,
        supplierName: supplierName,
        companyName: companyName,
        email: email,
        phone: phone,
        address: address,
        status: status,
      );
      await loadSuppliers();
      if (state.selectedSupplierDetail?.id == id) {
        await loadSupplierDetail(id);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> deleteSupplier(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _apiService.deleteSupplier(id);
      await loadSuppliers();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }
}

final supplierViewModelProvider =
    StateNotifierProvider<SupplierViewModel, SupplierListState>((ref) {
  return SupplierViewModel();
});
