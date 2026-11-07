import 'package:flutter/foundation.dart';
import 'package:supermarket_manager_system/data/local/session_local_store.dart';

class AppSession extends ChangeNotifier {
  AppSession._();

  static final AppSession instance = AppSession._();

  int? _userId;
  int? _roleId;
  String _fullName = '';
  String _role = '';
  bool _hydrated = false;

  int? get userId => _userId;
  int? get roleId => _roleId;
  String get fullName => _fullName;
  String get role => _role;
  bool get isLoggedIn => _userId != null;
  bool get isHydrated => _hydrated;

  Future<void> hydrateFromLocal() async {
    if (_hydrated) {
      return;
    }
    try {
      final snapshot = await SessionLocalStore.load();
      if (snapshot != null) {
        _userId = snapshot.userId;
        _roleId = snapshot.roleId;
        _fullName = snapshot.fullName;
        _role = snapshot.role;
      }
    } finally {
      _hydrated = true;
      notifyListeners();
    }
  }

  void setLogin({
    required int userId,
    required int roleId,
    required String fullName,
    required String role,
  }) {
    _userId = userId;
    _roleId = roleId;
    _fullName = fullName;
    _role = role;
    SessionLocalStore.save(
      userId: userId,
      roleId: roleId,
      fullName: fullName,
      role: role,
    );
    notifyListeners();
  }

  void clear() {
    _userId = null;
    _roleId = null;
    _fullName = '';
    _role = '';
    SessionLocalStore.clear();
    notifyListeners();
  }
}
