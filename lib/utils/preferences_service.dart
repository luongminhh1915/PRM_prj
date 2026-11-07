import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  PreferencesService._();
  static final PreferencesService instance = PreferencesService._();

  static const String _keyRememberMe = 'app_remember_me';
  static const String _keySavedUsername = 'app_saved_username';
  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keySalesPoint = 'app_sales_point';
  static const String _keyLastLogin = 'app_last_login';

  Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, value);
  }

  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  Future<void> setSavedUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySavedUsername, username);
  }

  Future<String?> getSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySavedUsername);
  }

  Future<void> setThemeMode(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, theme);
  }

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) ?? 'light';
  }

  Future<void> setSalesPoint(String salesPoint) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySalesPoint, salesPoint);
  }

  Future<String> getSalesPoint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySalesPoint) ?? 'Main Store';
  }

  Future<void> setLastLogin(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastLogin, time);
  }

  Future<String?> getLastLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastLogin);
  }

  Future<void> clearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

