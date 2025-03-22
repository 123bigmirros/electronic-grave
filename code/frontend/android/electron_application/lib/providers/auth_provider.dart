import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:electron_application/utils/http_client.dart';
import 'package:electron_application/utils/constants.dart';

class AuthProvider with ChangeNotifier {
  final HttpClient _httpClient = HttpClient();

  bool _isLoggedIn = false;
  String? _userId;
  String? _username;

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get username => _username;

  // 初始化方法，从本地存储加载用户信息
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString(StorageKeys.userId);
      _username = prefs.getString(StorageKeys.username);

      if (_userId != null && _userId != 'undefined') {
        _isLoggedIn = true;
        // 如果已登录，请求用户信息更新本地数据
        await getUserInfo();
      } else {
        _isLoggedIn = false;
        _userId = null;
        _username = null;
      }

      if (kDebugMode) {
        print(
            'AuthProvider初始化完成: isLoggedIn=$_isLoggedIn, userId=$_userId, username=$_username');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('AuthProvider初始化失败: $e');
      }
      _isLoggedIn = false;
      _userId = null;
      _username = null;
      notifyListeners();
    }
  }

  // 登录
  Future<bool> login(String username, String password) async {
    try {
      final response = await _httpClient.post(ApiEndpoints.login,
          data: {'username': username, 'password': password});

      if (kDebugMode) {
        print('登录响应: ${response['code']}, 数据: ${response['data']}');
      }

      if (response['code'] == 1 && response['data'] != null) {
        final userData = response['data'];
        if (userData['id'] != null && userData['id'] != -1) {
          _userId = userData['id'].toString();
          _username = userData['username'];
          _isLoggedIn = true;

          if (kDebugMode) {
            print('登录成功: 用户ID=$_userId, 用户名=$_username');
          }

          // 保存用户信息到本地存储
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(StorageKeys.userId, _userId!);
          await prefs.setString(StorageKeys.username, _username!);

          notifyListeners();
          return true;
        }
      }

      if (kDebugMode) {
        print('登录失败: ${response['msg']}');
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('登录异常: $e');
      }
      return false;
    }
  }

  // 注册
  Future<bool> register(String username, String password) async {
    try {
      final response = await _httpClient.post(
        ApiEndpoints.register,
        data: {'username': username, 'password': password},
      );

      if (response['code'] == 1 && response['data'] != null) {
        final userData = response['data'];
        if (userData['id'] != null && userData['id'] != -1) {
          _userId = userData['id'].toString();
          _username = userData['username'];
          _isLoggedIn = true;

          // 保存用户信息到本地存储
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(StorageKeys.userId, _userId!);
          await prefs.setString(StorageKeys.username, _username!);

          notifyListeners();
          return true;
        }
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('注册异常: $e');
      }
      return false;
    }
  }

  // 获取用户信息
  Future<void> getUserInfo() async {
    if (_userId == null || _userId!.isEmpty || _userId == 'undefined') {
      if (kDebugMode) {
        print('获取用户信息: 无效的用户ID');
      }
      _isLoggedIn = false;
      notifyListeners();
      return;
    }

    try {
      if (kDebugMode) {
        print('正在获取用户信息, 用户ID: $_userId');
      }
      final response = await _httpClient.post(ApiEndpoints.userInfo + '/get');

      if (kDebugMode) {
        print('获取用户信息响应: ${response['code']}, 数据: ${response['data']}');
      }

      if (response['code'] == 1 && response['data'] != null) {
        _username = response['data']['username'];
        _isLoggedIn = true;

        // 保存到本地存储
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(StorageKeys.username, _username!);

        notifyListeners();
      } else {
        if (kDebugMode) {
          print('获取用户信息失败: ${response['msg']}');
        }
        // 如果获取用户信息失败，可能是身份验证问题
        _isLoggedIn = false;
        notifyListeners();
      }
    } catch (e) {
      // 处理错误，可能是token过期等情况
      if (kDebugMode) {
        print('获取用户信息异常: $e');
      }
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  // 登出
  Future<void> logout() async {
    _isLoggedIn = false;
    _userId = null;
    _username = null;

    // 清除本地存储的用户信息
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.userId);
    await prefs.remove(StorageKeys.username);

    notifyListeners();
  }
}
