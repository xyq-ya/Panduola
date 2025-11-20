import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  int? _id;      // 存储用户 id
  int? get id => _id;

  static const String baseUrl = 'http://192.168.10.124:5000';
  
  void setId(int id) {
    _id = id;
    notifyListeners(); // 通知依赖这个数据的页面刷新
  }

  static String getApiUrl(String endpoint) {
    // 移除端点开头可能存在的斜杠
    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }
    return '$baseUrl/api/$endpoint';
  }
}