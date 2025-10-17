import 'package:flutter/material.dart';
import 'mind_map_page.dart';
import 'calendar_page.dart';
import 'log_page.dart';
import 'data_page.dart';
import 'profile_page.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class HomePage extends StatefulWidget {
  final int id;

  const HomePage({super.key, required this.id});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages =  [
    MindMapPage(),
    CalendarPage(),
    LogPage(),
    DataPage(),
    ProfilePage(),
  ];

  final List<String> _titles = ['导图', '日历', '日志', '数据', '我的'];

  void _onTabTapped(int idx) {
    setState(() => _selectedIndex = idx);
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
                final icons = [Icons.auto_graph, Icons.calendar_month, Icons.menu_book, Icons.pie_chart, Icons.account_circle];
                final labels = ['导图','日历','日志','数据','我的'];
                final active = _selectedIndex == i;
                return GestureDetector(
                  onTap: () => _onTabTapped(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icons[i], color: active ? const Color(0xFF3B82F6) : const Color(0xFF9CA3AF), size: 26),
                      const SizedBox(height: 6),
                      Text(labels[i], style: TextStyle(fontSize: 12, color: active ? const Color(0xFF2563EB) : Colors.grey)),
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