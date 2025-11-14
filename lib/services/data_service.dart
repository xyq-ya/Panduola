// lib/services/data_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class DataService {
  static Future<Map<String, dynamic>> getDashboardStats(int userId, {int days = 7}) async {
    try {
      // 直接硬编码完整URL
      const String requestUrl = 'http://localhost:5000/api/stats_dashboard';
      
      print('🚀 === 开始API请求 ===');
      print('🎯 目标URL: $requestUrl');
      print('📋 请求参数: user_id=$userId, days=$days');
      
      final response = await http.post(
        Uri.parse(requestUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'days': days,
        }),
      ).timeout(const Duration(seconds: 5));

      print('📡 响应状态: ${response.statusCode}');
      print('📝 响应体: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ API响应数据: $data');
        
        if (data['code'] == 0) {
          return data['data'] ?? {};
        } else {
          throw Exception('API返回错误: ${data['msg']}');
        }
      } else {
        throw Exception('HTTP错误: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 获取统计数据失败: $e');
      throw Exception('数据库连接失败: $e');
    }
  }
}