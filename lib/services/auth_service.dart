import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
// import '../models/user.dart';

class AuthService {
  static late SharedPreferences _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<bool> login(String username, String password) async {
    // In a real app, you would validate against a backend
    // For demo purposes, we'll use hardcoded credentials
    if (username == 'admin' && password == 'password') {
      await _prefs.setBool('isLoggedIn', true);
      await _prefs.setString('username', username);
      return true;
    }
    return false;
  }

  static Future<void> logout() async {
    await _prefs.setBool('isLoggedIn', false);
    await _prefs.remove('username');
  }

  static bool isLoggedIn() {
    return _prefs.getBool('isLoggedIn') ?? false;
  }

  static User? getCurrentUser() {
    final username = _prefs.getString('username');
    if (username != null) {
      return User(id: '1', username: username, name: '管理员');
    }
    return null;
  }

  static Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    // In a real app, you would validate against a backend
    // For demo purposes, we'll just check if current password is correct
    if (currentPassword == 'password') {
      // In a real app, you would update the password in the backend
      return true;
    }
    return false;
  }
}
