import 'package:flutter/material.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  Widget _calendarGrid(BuildContext context) {
    List<String> week = ['一','二','三','四','五','六','日'];
    // for demo, just show fixed dates like HTML
    List<String> days = [
      '29','30','31','1','2','3','4',
      '5','6','7','8','9','10','11',
      '12','13','14','15','16','17','18',
      '19','20','21','22','23','24','25'
    ];
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: week.map((w) => Text(w, style: const TextStyle(color: Colors.grey))).toList()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: days.map((d) {
            bool isToday = d == '17';
            bool highlight = d == '8' || d == '22';
            return Container(
              width: (MediaQuery.of(context).size.width - 40) / 7,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isToday ? const LinearGradient(colors: [Color(0xFFFFDE7D), Color(0xFFFFB740)]).createShader(Rect.zero) == null ? Colors.orange : null : (highlight ? Colors.pink.shade50 : null),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: isToday ? const Text('17', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : Text(d)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _ganttTask(String time, String title, Color bg, {String? rightLabel}) {
    return Row(
      children: [
        SizedBox(width: 72, child: Text(time, style: const TextStyle(color: Colors.grey))),
        Expanded(
          child: Container(
            height: 36,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(padding: const EdgeInsets.only(left: 12), child: Text(title, style: const TextStyle(color: Colors.white))),
            ),
          ),
        ),
        if (rightLabel != null) const SizedBox(width: 8),
        if (rightLabel != null) SizedBox(width: 64, child: Text(rightLabel, style: const TextStyle(color: Colors.grey))),
      ],
    );
  }

  Widget _planCard(String timeRange, String title, String tag, Color tagColor, String desc) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Icon(Icons.access_time, color: tagColor),
            const SizedBox(width: 8),
            Text(timeRange),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: tagColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Text(tag, style: TextStyle(color: tagColor)))
          ],
        ),
        const SizedBox(height: 8),
        Text(desc, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        Row(children: [const Icon(Icons.group, color: Colors.grey), const SizedBox(width: 6), const Text('会议室3，全员参加', style: TextStyle(color: Colors.grey))]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50, foregroundColor: Colors.blue), child: const Text('日')),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white), child: const Text('周')),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50, foregroundColor: Colors.blue), child: const Text('月')),
            ]),
            const SizedBox(height: 12),
            _calendarGrid(context),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  const Align(alignment: Alignment.centerLeft, child: Text('甘特图任务', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2563EB)))),
                  const SizedBox(height: 12),
                  _ganttTask('09:30', '团队周会', Colors.blue.shade700, rightLabel: '会议室3'),
                  const SizedBox(height: 8),
                  _ganttTask('14:00', '客户演示', Colors.pink.shade400, rightLabel: '重要客户'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerLeft, child: Text('今日计划', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2563EB)))),
            const SizedBox(height: 8),
            _planCard('09:30 - 团队周会', '09:30 - 团队周会', '会议', Colors.blue, '每周产品组例会，评审新方案'),
            const SizedBox(height: 12),
            _planCard('14:00 - 客户演示', '14:00 - 客户演示', '重要', Colors.pink, '向重要客户展示产品新功能模块'),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
