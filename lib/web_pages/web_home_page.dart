import 'package:flutter/material.dart';
import 'web_user_manage.dart';
import 'web_task_settings.dart';
import 'web_login.dart';

class WebHomePage extends StatefulWidget {
  const WebHomePage({super.key});

  @override
  State<WebHomePage> createState() => _WebHomePageState();
}

class _WebHomePageState extends State<WebHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    WebUserManagePage(),
    WebTaskSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildLeftMenu(context),
          Expanded(
            child: Container(
              color: const Color(0xFFF2F7FF), // 柔和淡蓝背景
              padding: const EdgeInsets.all(20),
              child: _pages[_selectedIndex],
            ),
          )
        ],
      ),
    );
  }

  /* ================================ 左侧菜单栏 ================================ */
  Widget _buildLeftMenu(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Text(
            "后台管理",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF42A5F5), // 蓝色
            ),
          ),
          const SizedBox(height: 40),

          _menuItem("员工管理", 0),
          _menuItem("任务设置", 1),

          const Spacer(),
          _menuItem("退出登录", -1, isLogout: true),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  /* ================================ 菜单按钮 ================================ */
  Widget _menuItem(String title, int index, {bool isLogout = false}) {
    bool active = _selectedIndex == index;

    return InkWell(
      onTap: () {
        if (isLogout) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WebLoginPage()),
          );
        } else {
          setState(() => _selectedIndex = index);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active ? Colors.lightBlue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              Icons.circle,
              size: 12,
              // 激活：蓝色；未激活：浅灰
              color: active ? const Color(0xFF42A5F5) : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? const Color(0xFF42A5F5) : Colors.black87,
              ),
            )
          ],
        ),
      ),
    );
  }
}