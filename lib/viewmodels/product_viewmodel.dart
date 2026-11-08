import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supermarket_manager_system/data/services/product_api_service.dart';
import 'package:supermarket_manager_system/models/category_option.dart';
import 'package:supermarket_manager_system/models/create_product_request.dart';
import 'package:supermarket_manager_system/models/product_detail.dart';
import 'package:supermarket_manager_system/models/product_list_item.dart';
import 'package:supermarket_manager_system/models/supplier_option.dart';
import 'package:supermarket_manager_system/models/update_product_request.dart';

class ProductListState {
  final bool isLoading;
  final List<ProductListItem> products;
  final List<ProductListItem> filteredProducts;
  final String searchQuery;
  final String? errorMessage;

  const ProductListState({
    this.isLoading = false,
    this.products = const [],
    this.filteredProducts = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  ProductListState copyWith({
    bool? isLoading,
    List<ProductListItem>? products,
    List<ProductListItem>? filteredProducts,
    String? searchQuery,
    String? errorMessage,
  }) {
    return ProductListState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}

class ProductViewModel extends StateNotifier<ProductListState> {
  final ProductApiService _apiService;

  ProductViewModel({ProductApiService? apiService})
      : _apiService = apiService ?? ProductApiService(),
        super(const ProductListState()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _apiService.getProducts();
      state = state.copyWith(
        isLoading: false,
        products: list,
        filteredProducts: _applyFilter(list, state.searchQuery),
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
      filteredProducts: _applyFilter(state.products, clean),
    );
  }

  List<ProductListItem> _applyFilter(
    List<ProductListItem> items,
    String query,
  ) {
    if (query.isEmpty) return items;
    return items.where((p) {
      return p.productName.toLowerCase().contains(query) ||
          p.barcode.toLowerCase().contains(query) ||
          p.categoryName.toLowerCase().contains(query);
    }).toList();
  }

  Future<ProductDetail> getProductById(int id) async {
    return _apiService.getProductById(id);
  }

  Future<ProductDetail> createProduct(CreateProductRequest request) async {
    final detail = await _apiService.createProduct(request);
    await loadProducts();
    return detail;
  }

  Future<ProductDetail> updateProduct(
    int id,
    UpdateProductRequest request,
  ) async {
    final detail = await _apiService.updateProduct(id, request);
    await loadProducts();
    return detail;
  }

  Future<void> deleteProduct(int id) async {
    await _apiService.deleteProduct(id);
    await loadProducts();
  }
}

final productViewModelProvider =
    StateNotifierProvider<ProductViewModel, ProductListState>((ref) {
  return ProductViewModel();
});

final categoryOptionsProvider =
    FutureProvider<List<CategoryOption>>((ref) async {
  return ProductApiService().getCategoryOptions();
});

final supplierOptionsProvider =
    FutureProvider<List<SupplierOption>>((ref) async {
  return ProductApiService().getSupplierOptions();
});
