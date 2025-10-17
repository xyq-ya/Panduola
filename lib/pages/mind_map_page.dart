import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class MindMapPage extends StatefulWidget {
  const MindMapPage({super.key});

  @override
  State<MindMapPage> createState() => _MindMapPageState();
}

class _MindMapPageState extends State<MindMapPage> {
  bool _showDropdown = false;
  String _headerTab = 'department'; // department / team / employee
  int? _userId; // 新增用户 id

  @override
  void initState() {
    super.initState();
    // 页面初始化时获取 Provider 中的 id
    _userId = Provider.of<UserProvider>(context, listen: false).id;
    print('MindMapPage 获取的用户 id: $_userId');
  }

  Widget _buildDepartmentHeader() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFA5D8FF), Color(0xFF87CEEB)], 
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight
        ),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.12), 
                      blurRadius: 6, 
                      offset: const Offset(0, 4)
                    )
                  ],
                  border: Border.all(color: const Color(0xFFC4DDFF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _headerTab == 'department' 
                      ? const Text('部门', style: TextStyle(fontWeight: FontWeight.bold)) 
                      : _headerTab == 'team' 
                        ? const Text('团队', style: TextStyle(fontWeight: FontWeight.bold)) 
                        : const Text('员工', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _card({required Widget child, EdgeInsets? margin}) {
    return Container(
      margin: margin ?? const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDepartmentHeader(), // 添加部门选择器
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final screenHeight = constraints.maxHeight;
              final cardWidth = (screenWidth - 36) / 2;
              final cardHeight = (screenHeight - 36) / 2;
              
              return SingleChildScrollView(
                child: Container(
                  height: screenHeight, // 设置固定高度确保均匀分布
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // 第一行：两个卡片
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    const Text(
                                      '公司十大事项', 
                                      style: TextStyle(
                                        fontSize: 16, 
                                        fontWeight: FontWeight.bold, 
                                        color: Color(0xFF1E3A8A)
                                      )
                                    ),
                                    const SizedBox(height: 10),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _priorityRow('Q4产品发布计划', Colors.redAccent, Colors.red.shade50),
                                          const SizedBox(height: 8),
                                          _priorityRow('年度预算审批', Colors.orange, Colors.yellow.shade50),
                                          const SizedBox(height: 8),
                                          _priorityRow('员工满意度调研', Colors.green, Colors.green.shade50),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '公司10大派发任务', 
                                      style: TextStyle(
                                        fontSize: 16, 
                                        fontWeight: FontWeight.bold, 
                                        color: Color(0xFFEC6A1E)
                                      )
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _taskRow('完成原型设计', '进行中', Colors.orange.shade100, Colors.orange),
                                          const SizedBox(height: 8),
                                          _taskRow('整理用户反馈', '已完成', Colors.green.shade100, Colors.green),
                                          const SizedBox(height: 8),
                                          _taskRow('测试报告编写', '进行中', Colors.orange.shade100, Colors.orange),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 第二行：两个卡片
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      '个人10大重要展示项', 
                                      style: TextStyle(
                                        fontSize: 16, 
                                        fontWeight: FontWeight.bold, 
                                        color: Color(0xFF6D28D9)
                                      )
                                    ),
                                    SizedBox(height: 8),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _SimpleRow(icon: Icons.circle_outlined, color: Colors.blue, title: '团队会议准备', time: '14:00'),
                                          SizedBox(height: 8),
                                          _SimpleRow(icon: Icons.circle_outlined, color: Colors.pink, title: '项目文档整理', time: '15:30'),
                                          SizedBox(height: 8),
                                          _SimpleRow(icon: Icons.check_circle, color: Colors.green, title: '周报提交（已完成）', time: ''),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '个人日志', 
                                      style: TextStyle(
                                        fontSize: 16, 
                                        fontWeight: FontWeight.bold, 
                                        color: Color(0xFFEC4899)
                                      )
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _logItem('张三', '已完成需求分析文档初稿', '08:45'),
                                          const SizedBox(height: 8),
                                          _logItem('李四', '测试环境部署完成，进入联调', '09:30'),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          ),
        ),
      ],
    );
  }

  Widget _priorityRow(String title, Color dot, Color bg) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), 
              color: bg, 
              border: Border.all(color: bg)
            ),
            child: Text(title, style: const TextStyle(fontSize: 13)),
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.circle, color: dot, size: 18),
      ],
    );
  }

  Widget _taskRow(String title, String state, Color bg, Color textColor) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.person, size: 16, color: Colors.grey),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 13))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Text(state, style: TextStyle(color: textColor, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _logItem(String name, String content, String time) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.person, size: 16, color: Colors.grey),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50, 
              borderRadius: BorderRadius.circular(12)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(content, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                Text(time, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
              ]
            ),
          ),
        ),
      ],
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
        decoration: highlight 
          ? BoxDecoration(
              color: const Color(0xFFEBF6FF), 
              borderRadius: BorderRadius.circular(6)
            ) 
          : null,
        child: Text(text, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}

class _SimpleRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String time;
  const _SimpleRow({required this.icon, required this.color, required this.title, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color),
      const SizedBox(width: 8),
      Expanded(child: Text(title)),
      if (time.isNotEmpty) Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }
}