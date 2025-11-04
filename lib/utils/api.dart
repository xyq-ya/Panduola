import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class Api {
  /// 返回适合当前运行平台的后端基址（不包含尾部斜杠）
  static String baseUrl() {
    // 支持通过 --dart-define=API_BASE_URL 在构建时覆盖（例如：指向开发机 IP）
    const envBase = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envBase.isNotEmpty) return envBase;

    if (kIsWeb) {
      // Web 端直接指向本机 Flask 服务，避免使用 origin(8080)
      return 'http://127.0.0.1:5000';
    }
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:5000';
      // 默认将桌面/模拟器指向你的开发机器 IP（已替换为用户提供的 192.168.10.37）
      return 'http://192.168.10.37:5000';
    } catch (e) {
      // 如果无法访问 Platform（安全回退）
      return 'http://192.168.10.37:5000';
    }
  }
}
