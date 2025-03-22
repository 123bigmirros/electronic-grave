import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4A6572);
  static const Color secondary = Color(0xFFF9AA33);
  static const Color background = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFBDBDBD);
}

class ApiEndpoints {
  static const String baseUrl = 'http://101.132.43.211:8090';

  // Python后端服务地址
  static const String pythonBaseUrl = 'http://101.132.43.211:5002';

  // 用户相关
  static const String userInfo = '/user/info';
  static const String login = userInfo + '/login';
  static const String register = userInfo + '/register';

  // 画布相关
  static const String canvas = '/user/canvas';
  static const String homeCanvas = canvas + '/load';
  static const String userCanvas = canvas + '/list';
  static const String saveCanvas = canvas + '/save';

  // Python服务端点
  static const String pythonBase = '/api';
  static const String deleteEmbedding = pythonBase + '/canvas/delete-embedding';
  static const String canvasEmbedding = pythonBase + '/canvas/embedding';
  static const String search = pythonBase + '/search';
  static const String chat = pythonBase + '/chat';

  // 上传相关
  static const String uploadImage = '/upload/image';
}

class StorageKeys {
  static const String token = 'auth_token';
  static const String userId = 'user_id';
  static const String username = 'username';
}

class ScreenSizes {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
}
