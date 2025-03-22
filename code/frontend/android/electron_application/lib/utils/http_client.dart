import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:electron_application/utils/constants.dart';

class HttpClient {
  // 单例模式
  static final HttpClient _instance = HttpClient._internal();
  factory HttpClient() => _instance;
  HttpClient._internal();

  // 默认超时时间
  final Duration _timeout = const Duration(seconds: 30);

  // 获取用户ID
  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // 创建带有用户ID的请求头
  Future<Map<String, String>> _createHeaders({
    Map<String, String>? additionalHeaders,
  }) async {
    final userId = await _getUserId();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (userId != null) {
      headers['userId'] = userId;
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  // GET请求
  Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requireAuth = true,
  }) async {
    try {
      final url = _getFullUrl(endpoint);
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http.get(Uri.parse(url), headers: headers);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('GET请求错误: $e');
      return {'code': 0, 'msg': '网络请求失败: $e'};
    }
  }

  // POST请求
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    bool usePythonServer = false,
  }) async {
    try {
      final url = _getFullUrl(endpoint, usePythonServer);
      final headers = await _getHeaders();
      final body = data != null ? json.encode(data) : null;
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      return _handleResponse(response);
    } catch (e) {
      debugPrint('POST请求错误: $e');
      return {'code': 0, 'msg': '网络请求失败: $e'};
    }
  }

  // PUT请求
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? data,
    bool usePythonServer = false,
  }) async {
    try {
      final url = _getFullUrl(endpoint, usePythonServer);
      final headers = await _getHeaders();
      final body = data != null ? json.encode(data) : null;
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      return _handleResponse(response);
    } catch (e) {
      debugPrint('PUT请求错误: $e');
      return {'code': 0, 'msg': '网络请求失败: $e'};
    }
  }

  // DELETE请求
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? data,
    bool usePythonServer = false,
  }) async {
    try {
      final url = _getFullUrl(endpoint, usePythonServer);
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
        body: data != null ? json.encode(data) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      debugPrint('DELETE请求错误: $e');
      return {'code': 0, 'msg': '网络请求失败: $e'};
    }
  }

  // 上传文件
  Future<Map<String, dynamic>> uploadFile(
      String endpoint, String filePath) async {
    try {
      final url = _getFullUrl(endpoint);
      final headers = await _getHeaders(isMultipart: true);
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(headers);
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath),
      );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('文件上传错误: $e');
      return {'code': 0, 'msg': '文件上传失败: $e'};
    }
  }

  // 处理响应
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return json.decode(body);
      } catch (e) {
        return {'code': 0, 'msg': '解析响应失败: $e', 'data': body};
      }
    } else {
      return {
        'code': 0,
        'msg': '服务器错误 ${response.statusCode}: ${response.reasonPhrase}',
      };
    }
  }

  // 获取完整的URL
  String _getFullUrl(String endpoint, [bool usePythonServer = false]) {
    final baseUrl =
        usePythonServer ? ApiEndpoints.pythonBaseUrl : ApiEndpoints.baseUrl;
    return '$baseUrl$endpoint';
  }

  // 获取请求头
  Future<Map<String, String>> _getHeaders({
    bool isMultipart = false,
    bool requireAuth = true,
  }) async {
    final headers = <String, String>{};

    if (!isMultipart) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }

    if (requireAuth) {
      // 从本地存储获取用户ID
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(StorageKeys.userId);
      if (userId != null && userId.isNotEmpty && userId != 'undefined') {
        headers['userId'] = userId;
        debugPrint('添加用户ID到请求头: $userId');
      } else {
        debugPrint('未找到有效的用户ID');
      }

      // 从本地存储获取令牌
      final token = prefs.getString(StorageKeys.token);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }
}
