import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class Api {
  /// 返回适合当前运行平台的后端基址（不包含尾部斜杠）
  static String baseUrl() {
    if (kIsWeb) {
      // 在 web 中使用当前 origin
      return Uri.base.origin;
    }
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:5000';
      // iOS 模拟器 与 桌面/本机 均可通过 localhost 访问
      return 'http://localhost:5000';
    } catch (e) {
      // 如果无法访问 Platform（安全回退）
      return 'http://localhost:5000';
    }
  }
}
