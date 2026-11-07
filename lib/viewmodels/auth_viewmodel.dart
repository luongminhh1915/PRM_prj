import 'package:flutter_riverpod/legacy.dart';
import 'package:supermarket_manager_system/data/services/auth_api_service.dart';
import 'package:supermarket_manager_system/models/login_result.dart';
import 'package:supermarket_manager_system/utils/app_session.dart';
import 'package:supermarket_manager_system/utils/preferences_service.dart';

class AuthState {
  final bool isLoading;
  final LoginResult? user;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    LoginResult? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthApiService _apiService;
  final PreferencesService _prefs;

  AuthViewModel({
    AuthApiService? apiService,
    PreferencesService? prefs,
  })  : _apiService = apiService ?? AuthApiService(),
        _prefs = prefs ?? PreferencesService.instance,
        super(const AuthState());

  Future<LoginResult> login({
    required String emailOrUsername,
    required String password,
    bool rememberMe = false,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _apiService.login(
        emailOrUsername: emailOrUsername,
        password: password,
      );

      AppSession.instance.setLogin(
        userId: result.userId,
        roleId: result.roleId,
        fullName: result.fullName,
        role: result.role,
      );

      if (rememberMe) {
        await _prefs.setRememberMe(true);
        await _prefs.setSavedUsername(emailOrUsername);
      } else {
        await _prefs.setRememberMe(false);
      }
      await _prefs.setLastLogin(DateTime.now().toIso8601String());

      state = state.copyWith(isLoading: false, user: result);
      return result;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      rethrow;
    }
  }

  Future<String> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final msg = await _apiService.forgotPassword(email);
      state = state.copyWith(isLoading: false);
      return msg;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<String> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final msg = await _apiService.verifyOtp(otp);
      state = state.copyWith(isLoading: false);
      return msg;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<String> resetPassword({
    required String otp,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final msg = await _apiService.resetPassword(
        otp: otp,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
      return msg;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  void logout() {
    AppSession.instance.clear();
    state = const AuthState();
  }
}

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel();
});

