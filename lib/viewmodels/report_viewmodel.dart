import 'package:flutter_riverpod/legacy.dart';
import 'package:supermarket_manager_system/data/services/report_api_service.dart';
import 'package:supermarket_manager_system/models/revenue_report_item.dart';

class ReportState {
  final bool isLoading;
  final List<RevenueReportItem> items;
  final int selectedYear;
  final int? selectedMonth;
  final double totalRevenue;
  final double cashRevenue;
  final double transferRevenue;
  final int totalOrders;
  final String? errorMessage;

  const ReportState({
    this.isLoading = false,
    this.items = const [],
    required this.selectedYear,
    this.selectedMonth,
    this.totalRevenue = 0.0,
    this.cashRevenue = 0.0,
    this.transferRevenue = 0.0,
    this.totalOrders = 0,
    this.errorMessage,
  });

  ReportState copyWith({
    bool? isLoading,
    List<RevenueReportItem>? items,
    int? selectedYear,
    int? selectedMonth,
    bool clearMonth = false,
    double? totalRevenue,
    double? cashRevenue,
    double? transferRevenue,
    int? totalOrders,
    String? errorMessage,
  }) {
    return ReportState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: clearMonth ? null : (selectedMonth ?? this.selectedMonth),
      totalRevenue: totalRevenue ?? this.totalRevenue,
      cashRevenue: cashRevenue ?? this.cashRevenue,
      transferRevenue: transferRevenue ?? this.transferRevenue,
      totalOrders: totalOrders ?? this.totalOrders,
      errorMessage: errorMessage,
    );
  }
}

class ReportViewModel extends StateNotifier<ReportState> {
  final ReportApiService _apiService;

  ReportViewModel({ReportApiService? apiService})
      : _apiService = apiService ?? ReportApiService(),
        super(ReportState(selectedYear: DateTime.now().year));

  Future<void> loadReport({int? year, int? month, bool clearMonth = false}) async {
    await Future<void>.delayed(Duration.zero);
    final targetYear = year ?? state.selectedYear;
    final targetMonth = clearMonth ? null : (month ?? state.selectedMonth);

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      selectedYear: targetYear,
      selectedMonth: targetMonth,
      clearMonth: clearMonth,
    );

    try {
      final items = await _apiService.getRevenueReport(
        year: targetYear,
        month: targetMonth,
      );

      double total = 0.0;
      double cash = 0.0;
      double transfer = 0.0;
      int orders = 0;

      for (final item in items) {
        total += item.totalRevenue;
        cash += item.cashRevenue;
        transfer += item.transferRevenue;
        orders += item.orderCount;
      }

      state = state.copyWith(
        isLoading: false,
        items: items,
        totalRevenue: total,
        cashRevenue: cash,
        transferRevenue: transfer,
        totalOrders: orders,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void changeYear(int year) {
    loadReport(year: year, month: state.selectedMonth);
  }

  void changeMonth(int? month) {
    if (month == null) {
      loadReport(year: state.selectedYear, clearMonth: true);
    } else {
      loadReport(year: state.selectedYear, month: month);
    }
  }
}

final reportViewModelProvider =
    StateNotifierProvider<ReportViewModel, ReportState>((ref) {
  return ReportViewModel();
});
