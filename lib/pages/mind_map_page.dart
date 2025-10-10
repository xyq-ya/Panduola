import 'package:flutter/material.dart';

class MindMapPage extends StatelessWidget {
  const MindMapPage({super.key});

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
    // two-column grid
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: (MediaQuery.of(context).size.width - 48) / 2,
                child: _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF87CEEB), borderRadius: BorderRadius.circular(12)),
                        child: const Text('重要', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(height: 8),
                      const Text('公司十大事项', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                      const SizedBox(height: 10),
                      Column(
                        children: [
                          _priorityRow('Q4产品发布计划', Colors.redAccent, Colors.red.shade50),
                          const SizedBox(height: 8),
                          _priorityRow('年度预算审批', Colors.orange, Colors.yellow.shade50),
                          const SizedBox(height: 8),
                          _priorityRow('员工满意度调研', Colors.green, Colors.green.shade50),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 48) / 2,
                child: _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('公司10大派发任务', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFEC6A1E))),
                      const SizedBox(height: 8),
                      _taskRow('完成原型设计', 'https://modao.cc/ai/uploads/ai_pics/24/249693/aigp_1757741567.jpeg', '进行中', Colors.orange.shade100, Colors.orange),
                      const SizedBox(height: 8),
                      _taskRow('整理用户反馈', 'https://modao.cc/ai/uploads/ai_pics/24/249694/aigp_1757741569.jpeg', '已完成', Colors.green.shade100, Colors.green),
                      const SizedBox(height: 8),
                      _taskRow('测试报告编写', 'https://modao.cc/ai/uploads/ai_pics/24/249695/aigp_1757741571.jpeg', '进行中', Colors.orange.shade100, Colors.orange),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 48) / 2,
                child: _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('个人10大重要展示项', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9))),
                      SizedBox(height: 8),
                      _SimpleRow(icon: Icons.circle_outlined, color: Colors.blue, title: '团队会议准备', time: '14:00'),
                      SizedBox(height: 8),
                      _SimpleRow(icon: Icons.circle_outlined, color: Colors.pink, title: '项目文档整理', time: '15:30'),
                      SizedBox(height: 8),
                      _SimpleRow(icon: Icons.check_circle, color: Colors.green, title: '周报提交（已完成）', time: ''),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 48) / 2,
                child: _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('个人日志', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFEC4899))),
                      const SizedBox(height: 8),
                      _logItem('张三', '已完成需求分析文档初稿', '08:45', 'https://modao.cc/ai/uploads/ai_pics/24/249696/aigp_1757741573.jpeg'),
                      const SizedBox(height: 8),
                      _logItem('李四', '测试环境部署完成，进入联调', '09:30', 'https://modao.cc/ai/uploads/ai_pics/24/249697/aigp_1757741576.jpeg'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priorityRow(String title, Color dot, Color bg) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: bg, border: Border.all(color: bg)),
            child: Text(title, style: const TextStyle(fontSize: 13)),
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.circle, color: dot, size: 18),
      ],
    );
  }

  Widget _taskRow(String title, String avatar, String state, Color bg, Color textColor) {
    return Row(
      children: [
        ClipOval(child: Image.network(avatar, width: 28, height: 28, fit: BoxFit.cover)),
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

  Widget _logItem(String name, String content, String time, String avatar) {
    return Row(
      children: [
        ClipOval(child: Image.network(avatar, width: 28, height: 28, fit: BoxFit.cover)),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(content, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 6),
              Text(time, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
            ]),
          ),
        ),
      ],
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
