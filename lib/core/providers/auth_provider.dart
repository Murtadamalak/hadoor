import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/authorized_users.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isInitialized = false;
  Map<String, String>? _currentUser;

  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  Map<String, String>? get currentUser => _currentUser;
  String get userName => _currentUser?['name'] ?? '';
  String get userCollege => _currentUser?['college'] ?? '';
  String get userUniversity => _currentUser?['university'] ?? '';
  String get userCode => _currentUser?['code'] ?? '';

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('user_code');
    if (savedCode != null) {
      final user = AuthorizedUsers.validate(savedCode);
      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String code) async {
    final user = AuthorizedUsers.validate(code);
    if (user != null) {
      _currentUser = user;
      _isLoggedIn = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_code', user['code']!);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_code');
    notifyListeners();
  }
}
