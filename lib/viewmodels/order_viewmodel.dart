import 'package:flutter_riverpod/legacy.dart';
import 'package:supermarket_manager_system/data/services/order_api_service.dart';
import 'package:supermarket_manager_system/models/checkout_invoice.dart';
import 'package:supermarket_manager_system/models/dashboard_summary.dart';
import 'package:supermarket_manager_system/models/dashboard_transaction.dart';
import 'package:supermarket_manager_system/models/order_detail.dart';
import 'package:supermarket_manager_system/models/order_list_item.dart';

class OrderListState {
  final bool isLoading;
  final List<OrderListItem> orders;
  final String? errorMessage;

  const OrderListState({
    this.isLoading = false,
    this.orders = const [],
    this.errorMessage,
  });

  OrderListState copyWith({
    bool? isLoading,
    List<OrderListItem>? orders,
    String? errorMessage,
  }) {
    return OrderListState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      errorMessage: errorMessage,
    );
  }
}

class OrderViewModel extends StateNotifier<OrderListState> {
  final OrderApiService _apiService;

  OrderViewModel({OrderApiService? apiService})
      : _apiService = apiService ?? OrderApiService(),
        super(const OrderListState());

  Future<void> loadOrders() async {
    await Future<void>.delayed(Duration.zero);
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _apiService.getOrders();
      state = state.copyWith(isLoading: false, orders: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<OrderDetail> getOrderDetail(int id) async {
    return _apiService.getOrderDetail(id);
  }

  Future<CheckoutInvoice> checkout({
    required int cashierId,
    required String customerName,
    required String customerPhone,
    required String paymentMethod,
    required double paid,
    required double discountPercent,
    int? discountId,
    String salesPoint = 'Main Store',
    required List<Map<String, dynamic>> items,
  }) async {
    final invoice = await _apiService.checkout(
      cashierId: cashierId,
      customerName: customerName,
      customerPhone: customerPhone,
      paymentMethod: paymentMethod,
      paid: paid,
      discountPercent: discountPercent,
      discountId: discountId,
      salesPoint: salesPoint,
      items: items,
    );
    await loadOrders();
    return invoice;
  }
}

final orderViewModelProvider =
    StateNotifierProvider<OrderViewModel, OrderListState>((ref) {
  return OrderViewModel();
});

class DashboardState {
  final bool isLoading;
  final DashboardSummary? summary;
  final List<DashboardTransaction> todayTransactions;
  final String? errorMessage;

  const DashboardState({
    this.isLoading = false,
    this.summary,
    this.todayTransactions = const [],
    this.errorMessage,
  });

  DashboardState copyWith({
    bool? isLoading,
    DashboardSummary? summary,
    List<DashboardTransaction>? todayTransactions,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      todayTransactions: todayTransactions ?? this.todayTransactions,
      errorMessage: errorMessage,
    );
  }
}

class DashboardViewModel extends StateNotifier<DashboardState> {
  final OrderApiService _apiService;

  DashboardViewModel({OrderApiService? apiService})
      : _apiService = apiService ?? OrderApiService(),
        super(const DashboardState());

  Future<void> loadDashboard() async {
    await Future<void>.delayed(Duration.zero);
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final summary = await _apiService.getDashboardSummary();
      final txs = await _apiService.getTodayTransactions();
      state = state.copyWith(
        isLoading: false,
        summary: summary,
        todayTransactions: txs,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final dashboardViewModelProvider =
    StateNotifierProvider<DashboardViewModel, DashboardState>((ref) {
  return DashboardViewModel();
});

