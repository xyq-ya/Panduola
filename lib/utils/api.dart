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
      return 'http://[2409:8900:1ac0:5b95:190f:ab8b:a7d0:2728]:5000';
    }
    try {
      if (Platform.isAndroid) return 'http://[2409:8900:1ac0:5b95:190f:ab8b:a7d0:2728]:5000';
      return 'http://[2409:8900:1ac0:5b95:190f:ab8b:a7d0:2728]:5000';
    } catch (e) {
      // 如果无法访问 Platform（安全回退）
      return 'http://10.0.2.2:5000';
    }
  }
}
