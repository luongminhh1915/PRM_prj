import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supermarket_manager_system/data/services/auth_api_service.dart';
import 'package:supermarket_manager_system/data/services/category_api_service.dart';
import 'package:supermarket_manager_system/data/services/customer_api_service.dart';
import 'package:supermarket_manager_system/data/services/expiration_api_service.dart';
import 'package:supermarket_manager_system/data/services/order_api_service.dart';
import 'package:supermarket_manager_system/data/services/product_api_service.dart';
import 'package:supermarket_manager_system/data/services/report_api_service.dart';
import 'package:supermarket_manager_system/data/services/supplier_api_service.dart';
import 'package:supermarket_manager_system/data/services/user_api_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('AuthApiService logs in correctly', () async {
    final authService = AuthApiService();
    final result = await authService.login(
      emailOrUsername: 'admin01',
      password: 'admin01',
    );

    expect(result.success, true);
    expect(result.role, 'ADMIN');
    expect(result.redirectTo, '/admin/dashboard');

    final resultPw = await authService.login(
      emailOrUsername: 'cashier01@supermarket.com',
      password: '123456',
    );
    expect(resultPw.success, true);
    expect(resultPw.role, 'CASHIER');
    expect(resultPw.redirectTo, '/cashier/open-shift');
  });

  test('User & Supplier & Expiration services work properly', () async {
    final userService = UserApiService();
    final supplierService = SupplierApiService();
    final expirationService = ExpirationApiService();

    final users = await userService.getUsers();
    expect(users.length, greaterThanOrEqualTo(4));

    final roles = await userService.getRoles();
    expect(roles.length, greaterThanOrEqualTo(3));

    final suppliers = await supplierService.getSuppliers();
    expect(suppliers.length, greaterThanOrEqualTo(5));

    final expStats = await expirationService.getExpirationStats();
    expect(expStats.expiresIn6Months, greaterThanOrEqualTo(0));
  });

  test('Product & Category services work properly', () async {
    final productService = ProductApiService();
    final categoryService = CategoryApiService();

    final products = await productService.getProducts();
    expect(products.length, greaterThanOrEqualTo(5));

    final categories = await categoryService.getCategories();
    expect(categories.length, greaterThanOrEqualTo(5));
  });

  test('Customer service works properly', () async {
    final customerService = CustomerApiService();

    final customers = await customerService.getCustomers();
    expect(customers.length, greaterThanOrEqualTo(5));
  });

  test('Checkout works and deducts stock', () async {
    final productService = ProductApiService();
    final orderService = OrderApiService();

    final productBefore = await productService.getProductById(1);
    final initialStock = productBefore.inStock;

    final invoice = await orderService.checkout(
      cashierId: 3,
      customerName: 'Nguyen Van A',
      customerPhone: '0900000001',
      paymentMethod: 'Cash',
      paid: 20000,
      discountPercent: 0,
      items: [
        {'productId': 1, 'qty': 2, 'kg': 1.0},
      ],
    );

    expect(invoice.orderNo.startsWith('INV-'), true);
    expect(invoice.items.length, 1);
    expect(invoice.totalPayable, 20000);

    final productAfter = await productService.getProductById(1);
    expect(productAfter.inStock, initialStock - 2);
  });

  test('Dashboard summary and revenue report work', () async {
    final orderService = OrderApiService();
    final reportService = ReportApiService();

    final summary = await orderService.getDashboardSummary();
    expect(summary.userCount, greaterThanOrEqualTo(4));
    expect(summary.supplierCount, greaterThanOrEqualTo(5));

    final report = await reportService.getRevenueReport(year: 2026);
    expect(report.length, 12);
  });
}
