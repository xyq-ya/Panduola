import 'package:flutter/material.dart';
<<<<<<< Updated upstream
=======
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/user_provider.dart';
>>>>>>> Stashed changes

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

<<<<<<< Updated upstream
=======
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

>>>>>>> Stashed changes
  Widget _profileItem(IconData icon, String title, Color color) {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.12), color.withOpacity(0.06)]), borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(12),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 13)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFDBF2FF), Color(0xFFE6FBFF)]), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28))),
            child: Column(children: [
              ClipOval(child: Image.network('https://modao.cc/ai/uploads/ai_pics/24/249698/aigp_1757741578.jpeg', width: 96, height: 96, fit: BoxFit.cover)),
              const SizedBox(height: 12),
              const Text('张小萌', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('高级产品经理', style: TextStyle(color: Color(0xFF3B82F6))),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(margin: const EdgeInsets.symmetric(horizontal: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]), child: Column(children: const [Text('234', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))), SizedBox(height: 4), Text('任务数', style: TextStyle(fontSize: 12, color: Colors.grey))])),
                Container(margin: const EdgeInsets.symmetric(horizontal: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]), child: Column(children: const [Text('92%', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)), SizedBox(height: 4), Text('完成率', style: TextStyle(fontSize: 12, color: Colors.grey))])),
              ]),
            ]),
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
        ]),
      ),
    );
  }
}
