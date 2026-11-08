import 'package:flutter_riverpod/legacy.dart';
import 'package:supermarket_manager_system/data/services/category_api_service.dart';
import 'package:supermarket_manager_system/models/category_list_item.dart';

class CategoryState {
  final bool isLoading;
  final List<CategoryListItem> categories;
  final String? errorMessage;

  const CategoryState({
    this.isLoading = false,
    this.categories = const [],
    this.errorMessage,
  });

  CategoryState copyWith({
    bool? isLoading,
    List<CategoryListItem>? categories,
    String? errorMessage,
  }) {
    return CategoryState(
      isLoading: isLoading ?? this.isLoading,
      categories: categories ?? this.categories,
      errorMessage: errorMessage,
    );
  }
}

class CategoryViewModel extends StateNotifier<CategoryState> {
  final CategoryApiService _apiService;

  CategoryViewModel({CategoryApiService? apiService})
      : _apiService = apiService ?? CategoryApiService(),
        super(const CategoryState()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _apiService.getCategories();
      state = state.copyWith(isLoading: false, categories: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<CategoryListItem> createCategory({
    required String name,
    required String status,
  }) async {
    final cat = await _apiService.createCategory(name: name, status: status);
    await loadCategories();
    return cat;
  }

  Future<CategoryListItem> updateCategory({
    required int id,
    required String name,
    required String status,
  }) async {
    final cat = await _apiService.updateCategory(
      id: id,
      name: name,
      status: status,
    );
    await loadCategories();
    return cat;
  }

  Future<void> deleteCategory(int id) async {
    await _apiService.deleteCategory(id);
    await loadCategories();
  }
}

final categoryViewModelProvider =
    StateNotifierProvider<CategoryViewModel, CategoryState>((ref) {
  return CategoryViewModel();
});

