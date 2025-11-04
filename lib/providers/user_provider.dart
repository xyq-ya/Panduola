import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  int? _id;      // 存储用户 id
  int? get id => _id;

  void setId(int id) {
    _id = id;
    notifyListeners(); // 通知依赖这个数据的页面刷新
  }
}