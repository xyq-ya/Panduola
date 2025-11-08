import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/user_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool loading = true;

  // 用户信息
  int? userId;
  String name = '';
  String role = '';
  String department = '';
  String team = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 确保 context 可用后再获取 Provider
    if (userId == null) {
      userId = Provider.of<UserProvider>(context, listen: false).id;
      print('当前用户 ID: $userId');
      if (userId != null) _fetchUserInfo(userId!);
    }
  }

  Future<void> _fetchUserInfo(int userId) async {
    try {
      final res = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/user_info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (res.statusCode != 200) {
        throw Exception('请求失败: ${res.statusCode}');
      }

      final body = jsonDecode(res.body);
      print('接口返回: $body');

      if (body['code'] != 0) {
        throw Exception('接口错误: ${body['msg']}');
      }

      final data = body['data'];
      setState(() {
        name = data['username'] ?? '';
        role = data['role_name'] ?? '';
        department = data['department'] ?? '';
        team = data['team'] ?? '';
        loading = false;
      });
    } catch (e) {
      print('获取用户信息失败: $e');
      setState(() {
        loading = false;
      });
    }
  }

  Widget _infoCard(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileItem(IconData icon, String title, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), color.withOpacity(0.06)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFDBF2FF), Color(0xFFE6FBFF)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    ClipOval(
                      child: Image.network(
                        'https://modao.cc/ai/uploads/ai_pics/24/249698/aigp_1757741578.jpeg',
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(role, style: const TextStyle(color: Color(0xFF3B82F6))),
                    const SizedBox(height: 12),
                    _infoCard('所属部门', department, const Color(0xFF2563EB)),
                    _infoCard('所属团队', team, const Color(0xFF16A34A)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _profileItem(Icons.settings, '系统设置', const Color(0xFF5C6BC0)),
                    _profileItem(Icons.notifications, '消息中心', const Color(0xFFFF9800)),
                    _profileItem(Icons.book, '项目文档', const Color(0xFF66BB6A)),
                    _profileItem(Icons.group, '团队成员', const Color(0xFFF44336)),
                    _profileItem(Icons.pie_chart, '数据报表', const Color(0xFF9C27B0)),
                    _profileItem(Icons.help, '帮助中心', const Color(0xFF03A9F4)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
