import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthProvider() {
    _initialize();
  }

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    if (AuthService.isLoggedIn()) {
      _currentUser = AuthService.getCurrentUser();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await AuthService.login(username, password);
      if (success) {
        _currentUser = AuthService.getCurrentUser();
      } else {
        _error = '用户名或密码错误';
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = '登录失败: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await AuthService.logout();
    _currentUser = null;

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await AuthService.changePassword(
        currentPassword,
        newPassword,
      );
      if (!success) {
        _error = '当前密码错误';
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = '修改密码失败: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
