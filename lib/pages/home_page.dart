import 'package:flutter/material.dart';
import 'mind_map_page.dart';
import 'calendar_page.dart';
import 'log_page.dart';
import 'data_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _showDropdown = false;
  String _headerTab = 'department'; // department / team / employee

  final List<Widget> _pages = const [
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

  Widget _buildHeader() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFA5D8FF), Color(0xFF87CEEB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border(bottom: BorderSide(color: Color(0xFFD1E8FF), width: 2)),
      ),
      child: Stack(
        children: [
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _showDropdown = !_showDropdown),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 4))],
                  border: Border.all(color: const Color(0xFFC4DDFF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _headerTab == 'department' ? const Text('部门', style: TextStyle(fontWeight: FontWeight.bold)) :
                    _headerTab == 'team' ? const Text('团队', style: TextStyle(fontWeight: FontWeight.bold)) :
                    const Text('员工', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_drop_down, size: 20, color: Colors.black54)
                  ],
                ),
              ),
            ),
          ),
          if (_showDropdown)
            Positioned(
              top: 60,
              left: MediaQuery.of(context).size.width / 2 - 100,
              child: _DropdownBubble(
                selected: _headerTab,
                onSelect: (v) => setState(() {
                  _headerTab = v;
                  _showDropdown = false;
                }),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // scaffold with header built above to mimic the framed phone look
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          _buildHeader(),
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

class _DropdownBubble extends StatelessWidget {
  final Function(String) onSelect;
  final String selected;
  const _DropdownBubble({required this.onSelect, required this.selected, super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE9ECEF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bubbleItem('技术研发中心', 'department'),
            const SizedBox(height: 6),
            _bubbleItem('产品设计中心', 'department', highlight: true),
            const SizedBox(height: 6),
            _bubbleItem('市场营销部', 'department'),
            const SizedBox(height: 6),
            _bubbleItem('UI设计组', 'team'),
            const SizedBox(height: 6),
            _bubbleItem('张三', 'employee'),
          ],
        ),
      ),
    );
  }

  Widget _bubbleItem(String text, String tag, {bool highlight = false}) {
    return GestureDetector(
      onTap: () => onSelect(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: highlight ? BoxDecoration(color: const Color(0xFFEBF6FF), borderRadius: BorderRadius.circular(6)) : null,
        child: Text(text, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}
