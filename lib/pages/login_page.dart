import 'package:flutter/material.dart';
import 'home_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
  final username = _usernameController.text.trim();
  final password = _passwordController.text.trim();

  if (username.isEmpty || password.isEmpty) {
    _showErrorDialog('请输入用户名和密码');
    return;
  }

  setState(() => _isLoading = true);

  try {
    // 使用 Android 模拟器访问本地 Flask 服务
  final url = Uri.parse('http://10.0.2.2:5000/api/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['id'] != null) {

      Provider.of<UserProvider>(context, listen: false).setId(data['id']);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(id: data['id']),
        ),
      );
    } else {
      _showErrorDialog(data['error'] ?? '登录失败，请检查用户名和密码');
    }
  } catch (e) {
    _showErrorDialog('无法连接服务器，请检查网络或服务器状态');
  } finally {
    setState(() => _isLoading = false);
  }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2563EB),
              Color(0xFF3B82F6),
              Color(0xFF60A5FA),
            ],
          ),
        ),
        child: Column(
          children: [
            // 顶部留白和标题
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    // 应用图标
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 40,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '潘多拉掌上工具系统',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pandora Mobile Tools System',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 登录表单区域
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // 欢迎文字
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '欢迎登录',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '请使用您的账号密码登录系统',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 用户名输入框
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person_outline, color: Color(0xFF6B7280)),
                            hintText: '请输入用户名',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 密码输入框
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6B7280)),
                            hintText: '请输入密码',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: const Color(0xFF6B7280),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 记住我和忘记密码
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value!;
                                  });
                                },
                                activeColor: const Color(0xFF2563EB),
                              ),
                              const Text(
                                '记住我',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              // 忘记密码功能
                              _showErrorDialog('忘记密码功能开发中...');
                            },
                            child: const Text(
                              '忘记密码？',
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // 登录按钮
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  '登录',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const Spacer(),
                      const SizedBox(height: 20),

                      // 版本信息
                      const Text(
                        '版本 1.0.0',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
