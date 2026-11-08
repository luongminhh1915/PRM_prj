import 'package:flutter_riverpod/legacy.dart';
import 'package:supermarket_manager_system/data/services/expiration_api_service.dart';
import 'package:supermarket_manager_system/models/expiration_product.dart';
import 'package:supermarket_manager_system/models/expiration_stats.dart';

class ExpirationState {
  final bool isLoading;
  final ExpirationStats? stats;
  final List<ExpirationProduct> products;
  final String activeTab; // 'today', '7days', '3months', '6months'
  final String? errorMessage;

  const ExpirationState({
    this.isLoading = false,
    this.stats,
    this.products = const [],
    this.activeTab = 'today',
    this.errorMessage,
  });

  ExpirationState copyWith({
    bool? isLoading,
    ExpirationStats? stats,
    List<ExpirationProduct>? products,
    String? activeTab,
    String? errorMessage,
  }) {
    return ExpirationState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      products: products ?? this.products,
      activeTab: activeTab ?? this.activeTab,
      errorMessage: errorMessage,
    );
  }
}

class ExpirationViewModel extends StateNotifier<ExpirationState> {
  final ExpirationApiService _apiService;

  ExpirationViewModel({ExpirationApiService? apiService})
      : _apiService = apiService ?? ExpirationApiService(),
        super(const ExpirationState()) {
    loadStats();
    loadTab('today');
  }

  Future<void> loadStats() async {
    try {
      final stats = await _apiService.getExpirationStats();
      state = state.copyWith(stats: stats);
    } catch (_) {}
  }

  Future<void> loadTab(String tab) async {
    state = state.copyWith(isLoading: true, activeTab: tab, errorMessage: null);
    try {
      List<ExpirationProduct> list = [];
      if (tab == 'today') {
        list = await _apiService.getProductsExpiringToday();
      } else if (tab == '7days') {
        list = await _apiService.getProductsExpiringIn7Days();
      } else if (tab == '3months') {
        list = await _apiService.getProductsExpiringIn3Months();
      } else if (tab == '6months') {
        list = await _apiService.getProductsExpiringIn6Months();
      }
      state = state.copyWith(isLoading: false, products: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final expirationViewModelProvider =
    StateNotifierProvider<ExpirationViewModel, ExpirationState>((ref) {
  return ExpirationViewModel();
});

