import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supermarket_manager_system/viewmodels/auth_viewmodel.dart';
import 'package:supermarket_manager_system/viewmodels/category_viewmodel.dart';
import 'package:supermarket_manager_system/viewmodels/customer_viewmodel.dart';
import 'package:supermarket_manager_system/viewmodels/expiration_viewmodel.dart';
import 'package:supermarket_manager_system/viewmodels/order_viewmodel.dart';
import 'package:supermarket_manager_system/viewmodels/product_viewmodel.dart';
import 'package:supermarket_manager_system/viewmodels/report_viewmodel.dart';
import 'package:supermarket_manager_system/viewmodels/supplier_viewmodel.dart';
import 'package:supermarket_manager_system/viewmodels/user_viewmodel.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('MVVM: AuthViewModel handles login with Riverpod ProviderContainer',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final authVm = container.read(authViewModelProvider.notifier);
    final result = await authVm.login(
      emailOrUsername: 'admin01',
      password: 'admin01',
      rememberMe: true,
    );

    expect(result.role, 'ADMIN');
    final authState = container.read(authViewModelProvider);
    expect(authState.user?.username, 'admin01');
    expect(authState.isLoading, false);
  });

  test('MVVM: ProductViewModel & CategoryViewModel manage state correctly',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final productVm = container.read(productViewModelProvider.notifier);
    await productVm.loadProducts();

    final productState = container.read(productViewModelProvider);
    expect(productState.products.length, greaterThanOrEqualTo(5));

    productVm.search('Coca');
    final filteredState = container.read(productViewModelProvider);
    expect(filteredState.filteredProducts.length, 1);

    final catVm = container.read(categoryViewModelProvider.notifier);
    await catVm.loadCategories();
    final catState = container.read(categoryViewModelProvider);
    expect(catState.categories.length, greaterThanOrEqualTo(5));
  });

  test('MVVM: OrderViewModel & DashboardViewModel manage transactions',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final orderVm = container.read(orderViewModelProvider.notifier);
    await orderVm.loadOrders();
    final orderState = container.read(orderViewModelProvider);
    expect(orderState.orders.length, greaterThanOrEqualTo(5));

    final dashVm = container.read(dashboardViewModelProvider.notifier);
    await dashVm.loadDashboard();
    final dashState = container.read(dashboardViewModelProvider);
    expect(dashState.summary?.userCount, greaterThanOrEqualTo(4));
  });

  test('MVVM: Customer, Supplier, User, Expiration, Report ViewModels work',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final custVm = container.read(customerViewModelProvider.notifier);
    await custVm.loadCustomers();
    expect(container.read(customerViewModelProvider).customers.length,
        greaterThanOrEqualTo(5));

    final suppVm = container.read(supplierViewModelProvider.notifier);
    await suppVm.loadSuppliers();
    expect(container.read(supplierViewModelProvider).suppliers.length,
        greaterThanOrEqualTo(5));

    final userVm = container.read(userViewModelProvider.notifier);
    await userVm.loadUsers();
    expect(container.read(userViewModelProvider).users.length,
        greaterThanOrEqualTo(4));

    final expVm = container.read(expirationViewModelProvider.notifier);
    await expVm.loadStats();
    expect(container.read(expirationViewModelProvider).stats, isNotNull);

    final repVm = container.read(reportViewModelProvider.notifier);
    await repVm.loadReport();
    expect(container.read(reportViewModelProvider).reportItems.length, 12);
  });
}
