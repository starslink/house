import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  // 初始化服务
  static Future<void> initialize() async {
    // 检查是否有存储的令牌
    await ApiService.getToken();
  }

  // 登录方法
  static Future<bool> login(String username, String password) async {
    try {
      final response = await ApiService.post('/auth/login', {
        'username': username,
        'password': password,
      });

      if (response != null && response['code'] == 200) {
        final data = response['data'];
        await ApiService.saveToken(data['token']);
        return true;
      }
      return false;
    } catch (e) {
      print('登录失败: ${e.toString()}');
      return false;
    }
  }

  // 登出方法
  static Future<void> logout() async {
    try {
      // 调用后端登出接口
      await ApiService.post('/auth/logout', {});
    } catch (e) {
      // 忽略登出时的错误
    } finally {
      // 无论如何都要清除本地令牌
      await ApiService.removeToken();
    }
  }

  // 检查是否已登录
  static Future<bool> isLoggedIn() async {
    final token = await ApiService.getToken();
    return token != null;
  }

  // 获取当前用户信息
  static Future<User?> getCurrentUser() async {
    try {
      final response = await ApiService.get('/auth/me');

      if (response != null && response['code'] == 200) {
        final userData = response['data'];
        return User(
          id: userData['id'],
          username: userData['username'],
          name: userData['name'],
        );
      }
      return null;
    } catch (e) {
      print('获取用户信息失败: $e');
      return null;
    }
  }

  // 修改密码
  static Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await ApiService.post('/auth/change-password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      return response != null && response['code'] == 200;
    } catch (e) {
      print('修改密码失败: $e');
      return false;
    }
  }
}
