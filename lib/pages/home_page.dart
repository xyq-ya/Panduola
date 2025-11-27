import 'package:flutter/material.dart';
import 'mind_map_page.dart';
import 'calendar_page.dart';
import 'log_page.dart';
import 'data_page.dart';
import 'profile_page.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/user_provider.dart';

class HomePage extends StatefulWidget {
  final int id;
  static final GlobalKey<_HomePageState> homeKey = GlobalKey<_HomePageState>();

  const HomePage({super.key, required this.id});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _unreadCount = 0;  // ⭐ 未读数量

  final List<Widget> _pages = [
    MindMapPage(),
    CalendarPage(),
    LogPage(),
    DataPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    fetchUnreadCount();
  }

  // ⭐ 请求后端获取未读消息数量
  Future<void> fetchUnreadCount() async {
    try {
      final String urlStr = UserProvider.getApiUrl('get_unread_message_count');
      final Uri url = Uri.parse(urlStr);

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": widget.id}),
      );

      final resp = jsonDecode(response.body);

      if (resp["code"] == 0) {
        setState(() {
          _unreadCount = resp["data"]["count"];
        });
      }
    } catch (e) {
      print("获取未读数量失败: $e");
    }
  }

  void _onTabTapped(int idx) {
    setState(() => _selectedIndex = idx);
    fetchUnreadCount(); // ⭐ 切换 tab 时刷新
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Expanded(child: _pages[_selectedIndex]),
          Container(
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (i) {
                final icons = [
                  Icons.auto_graph,
                  Icons.calendar_month,
                  Icons.menu_book,
                  Icons.pie_chart,
                  Icons.account_circle
                ];
                final labels = ['导图', '日历', '日志', '数据', '我的'];
                final active = _selectedIndex == i;

                // ⭐ "我的" 加角标
                Widget iconWidget = Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icons[i],
                      color: active
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF9CA3AF),
                      size: 26,
                    ),

                    // 🔴 未读红点（仅在 “我的” 且数量 > 0 时显示）
                    if (i == 4 && _unreadCount > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                );

                return GestureDetector(
                  onTap: () => _onTabTapped(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      iconWidget,
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 12,
                          color: active
                              ? const Color(0xFF2563EB)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}