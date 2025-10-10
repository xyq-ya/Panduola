import 'package:flutter/material.dart';

class DataPage extends StatelessWidget {
  const DataPage({super.key});

  Widget _statCard(String title, String subtitle, Color color, double percent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Row(children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Center(child: Text('${(percent*100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(subtitle, style: const TextStyle(color: Colors.grey))])),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tags = ['优化','会议','设计','开发','测试','部署','文档','迭代'];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
            child: Wrap(spacing: 8, runSpacing: 8, children: tags.map((t) => Chip(label: Text(t), backgroundColor: Colors.blue.shade50)).toList()),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _statCard('任务进度分布', '已完成: 65% · 进行中: 20% · 未开始: 15%', Colors.green, 0.65)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('优先级分布', '高:18 · 中:35 · 低:47', Colors.orange, 0.47)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('AI建议助手', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.smart_toy, color: Color(0xFF8A3FFC))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('建议将周四的团队会议调整为线上进行', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Text('平均可节省每位成员45分钟通勤时间', style: TextStyle(color: Colors.grey)),
                ])),
                TextButton(onPressed: () {}, child: const Text('采纳建议 →'))
              ])
            ]),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}
