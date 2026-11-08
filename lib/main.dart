import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:supermarket_manager_system/data/local/database_initializer.dart';
import 'package:supermarket_manager_system/utils/app_session.dart';
import 'package:supermarket_manager_system/views/login_page.dart';
import 'package:supermarket_manager_system/views/forgot_password_page.dart';
import 'package:supermarket_manager_system/views/verify_otp_page.dart';
import 'package:supermarket_manager_system/views/set_new_password_page.dart';
import 'package:supermarket_manager_system/views/role_home_page.dart';
import 'package:supermarket_manager_system/views/cashier_open_shift_page.dart';
import 'package:supermarket_manager_system/views/cashier_dashboard_page.dart';
import 'package:supermarket_manager_system/views/users_page.dart';
import 'package:supermarket_manager_system/views/user_detail_page.dart';
import 'package:supermarket_manager_system/views/customers_page.dart';
import 'package:supermarket_manager_system/views/orders_page.dart';
import 'package:supermarket_manager_system/views/creditors_page.dart';
import 'package:supermarket_manager_system/views/manager_dashboard_page.dart';
import 'package:supermarket_manager_system/views/admin_dashboard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  await initDatabase();
  await AppSession.instance.hydrateFromLocal();

  runApp(const ProviderScope(child: SupermarketManagerApp()));
}

class SupermarketManagerApp extends StatelessWidget {
  const SupermarketManagerApp({super.key});

  static final GoRouter _router = GoRouter(
    initialLocation: '/login',
    refreshListenable: AppSession.instance,
    redirect: (context, state) {
      final path = state.uri.path;
      final isLoggedIn = AppSession.instance.isLoggedIn;
      final isPublicRoute =
          path == '/login' ||
          path == '/' ||
          path == '/forgot-password' ||
          path == '/verify-otp' ||
          path == '/set-new-password';

      if (!isLoggedIn && !isPublicRoute) {
        return '/login';
      }

      if (isLoggedIn && (path == '/login' || path == '/')) {
        return '/role-home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/login',
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return VerifyOtpPage(email: email);
        },
      ),
      GoRoute(
        path: '/set-new-password',
        builder: (context, state) {
          final otp = state.uri.queryParameters['otp'] ?? '';
          return SetNewPasswordPage(otp: otp);
        },
      ),
      GoRoute(
        path: '/role-home',
        builder: (context, state) => RoleHomePage(
          role: AppSession.instance.role,
          fullName: AppSession.instance.fullName,
        ),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => AdminDashboardPage(
          fullName: AppSession.instance.fullName,
          userId: AppSession.instance.userId ?? 1,
        ),
      ),
      GoRoute(
        path: '/manager/dashboard',
        builder: (context, state) => ManagerDashboardPage(
          fullName: AppSession.instance.fullName,
          userId: AppSession.instance.userId ?? 2,
        ),
      ),
      GoRoute(
        path: '/cashier/open-shift',
        builder: (context, state) => CashierOpenShiftPage(
          fullName: AppSession.instance.fullName,
        ),
      ),
      GoRoute(
        path: '/cashier/dashboard',
        builder: (context, state) => CashierDashboardPage(
          fullName: AppSession.instance.fullName,
          userId: AppSession.instance.userId ?? 0,
          initialTabKey: 'scanner',
          initialPhone: '',
          initialOrderId: null,
          onNavigatePath: (path) => context.go(path),
          onLogoutRequested: () {
            AppSession.instance.clear();
            context.go('/login');
          },
        ),
      ),
      GoRoute(
        path: '/users',
        builder: (context, state) => const UsersPage(),
      ),
      GoRoute(
        path: '/user-detail/:userId',
        builder: (context, state) {
          final userId = int.tryParse(state.pathParameters['userId'] ?? '0') ?? 0;
          return UserDetailPage(userId: userId);
        },
      ),
      GoRoute(
        path: '/customers',
        builder: (context, state) => const CustomersPage(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersPage(),
      ),
      GoRoute(
        path: '/creditors',
        builder: (context, state) => const CreditorsPage(),
      ),
      GoRoute(
        path: '/admin',
        redirect: (context, state) => '/admin/dashboard',
      ),
      GoRoute(
        path: '/manager',
        redirect: (context, state) => '/manager/dashboard',
      ),
      GoRoute(
        path: '/cashier',
        redirect: (context, state) => '/cashier/open-shift',
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Supermarket Manager',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Segoe UI',
      ),
      routerConfig: _router,
    );
  }
}
