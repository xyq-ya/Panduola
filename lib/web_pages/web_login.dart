import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../providers/user_provider.dart';
import 'web_home_page.dart';

class WebLoginPage extends StatefulWidget {
  const WebLoginPage({super.key});

  @override
  State<WebLoginPage> createState() => _WebLoginPageState();
}

class _WebLoginPageState extends State<WebLoginPage> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _isLoading = false;

  // 弹窗提示
  Future<void> _showAlert(String msg) async {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("提示", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("确定"),
          )
        ],
      ),
    );
  }

  Future<void> _login() async {
    final username = _username.text.trim();
    final password = _password.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showAlert("用户名和密码不能为空");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = UserProvider.getApiUrl("login");
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        int userId = data["id"];

        // 获取权限
        final infoUrl = UserProvider.getApiUrl("user_info");
        final infoResp = await http.post(
          Uri.parse(infoUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"user_id": userId}),
        );

        final infoData = jsonDecode(infoResp.body);

        if (infoData["code"] != 0) {
          _showAlert("获取用户信息失败");
          setState(() => _isLoading = false);
          return;
        }

        final roleId = infoData["data"]["role_id"];

        // 权限判断
        if (roleId > 2) {
          _showAlert("权限不足，无法进入后台系统");
          setState(() => _isLoading = false);
          return;
        }

        // 成功跳转
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WebHomePage()),
        );
      } else {
        _showAlert(data["error"] ?? "登录失败");
      }
    } catch (e) {
      _showAlert("网络错误，请检查服务器");
    }

    setState(() => _isLoading = false); // 必须放最后
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ------------------ 蓝白卡通背景 ------------------
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade100,
                    Colors.lightBlue.shade200,
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // 卡通云朵
          Positioned(
            top: 80,
            left: 40,
            child: Opacity(
              opacity: 0.25,
              child: Icon(Icons.cloud, size: 200, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 40,
            right: 50,
            child: Opacity(
              opacity: 0.20,
              child: Icon(Icons.cloud, size: 240, color: Colors.white),
            ),
          ),

          // 登录框
          Center(
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                      color: Colors.blue.shade200,
                      blurRadius: 25,
                      offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "员工管理后台登录",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 用户名
                  TextField(
                    controller: _username,
                    decoration: InputDecoration(
                      labelText: "用户名",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 密码
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "密码",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 登录按钮
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: Text(
                        _isLoading ? "登录中..." : "登录",
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}