import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class Api {
  /// 返回适合当前运行平台的后端基址（不包含尾部斜杠）
  static String baseUrl() {
    // 支持通过 --dart-define=API_BASE_URL 在构建时覆盖（例如：指向开发机 IP）
    const envBase = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envBase.isNotEmpty) return envBase;

    if (kIsWeb) {
      // Web 端直接使用当前局域网 IP
      return 'http://192.168.128.39:5000';
    }
    try {
      // Android 模拟器访问宿主机要使用 10.0.2.2
      if (Platform.isAndroid) return 'http://10.0.2.2:5000';
      // 其他平台（Windows/macOS 等）继续使用局域网 IP
      return 'http://192.168.128.39:5000';
    } catch (e) {
      // 如果无法访问 Platform（安全回退）
      return 'http://10.0.2.2:5000';
    }
  }
}
