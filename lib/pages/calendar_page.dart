import 'package:flutter/material.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDate = DateTime(2025, 10, 1);

  // 示例任务（固定时间示例）
  final List<GanttTask> _tasks = [
    GanttTask(
      name: 'PRD骨架',
      startDate: DateTime(2025, 10, 10),
      endDate: DateTime(2025, 10, 12),
      progress: 1.0,
      color: const Color(0xFF1976D2),
      isMilestone: false,
    ),
    GanttTask(
      name: 'PRD文档收集',
      startDate: DateTime(2025, 10, 12),
      endDate: DateTime(2025, 10, 17),
      progress: 0.8,
      color: const Color(0xFF388E3C),
      isMilestone: false,
    ),
    GanttTask(
      name: '定稿（里程碑）',
      startDate: DateTime(2025, 10, 17),
      endDate: DateTime(2025, 10, 17),
      progress: 1.0,
      color: const Color(0xFFF57C00),
      isMilestone: true,
    ),
    GanttTask(
      name: '任务拆分及甘特图',
      startDate: DateTime(2025, 10, 18),
      endDate: DateTime(2025, 10, 22),
      progress: 0.6,
      color: const Color(0xFF7B1FA2),
      isMilestone: false,
    ),
    // 可继续添加任务
  ];

  // 小工具：格式化年月（不依赖 intl）
  String _formatYearMonth(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    return '${d.year} 年 $m 月';
  }

  // 小工具：格式化 MM/dd
  String _formatMd(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$m/$day';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2018),
      lastDate: DateTime(2035),
      helpText: '选择查看月份（会跳到具体日期，取其年月）',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  // 年月选择卡片（样式接近 LogPage）
  Widget _buildDateSelectorCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _formatYearMonth(_selectedDate),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
          ),
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.date_range),
            label: const Text('选择时间'),
          ),
        ],
      ),
    );
  }

  // 大尺寸任务卡片（当月的任务，视觉更突出 + 查看详情按钮）
Widget _buildMonthlyTaskCard(GanttTask t) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: t.color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: t.color.withOpacity(0.22)),
      boxShadow: [
        BoxShadow(
          color: t.color.withOpacity(0.08),
          blurRadius: 6,
          offset: const Offset(0, 3),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.name,
          style: TextStyle(
            color: t.color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${_formatMd(t.startDate)} - ${_formatMd(t.endDate)}',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 10),
        // 进度长条
        LayoutBuilder(builder: (context, constraints) {
          final max = constraints.maxWidth;
          final barFull = max * 0.78;
          final progressW = barFull * t.progress;
          return Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 22,
                    width: barFull,
                    decoration: BoxDecoration(
                      color: t.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Container(
                    height: 22,
                    width: progressW,
                    decoration: BoxDecoration(
                      color: t.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: t.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(t.progress * 100).toInt()}%',
                      style: TextStyle(
                        color: t.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
        const SizedBox(height: 10),
        // ✅ 新增：查看详情按钮
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(t.name,
                      style: TextStyle(
                          color: t.color, fontWeight: FontWeight.bold)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('开始日期：${_formatMd(t.startDate)}'),
                      Text('结束日期：${_formatMd(t.endDate)}'),
                      Text('完成进度：${(t.progress * 100).toInt()}%'),
                      if (t.isMilestone)
                        const Text('类型：里程碑',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('关闭'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.info_outline, size: 20),
            label: const Text('查看详情'),
            style: TextButton.styleFrom(
              foregroundColor: t.color,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ),
  );
}


  // 甘特图：水平可滚动，日期刻度 + 任务条（任务区域高度固定以避免布局出错）
  Widget _buildGanttChart() {
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final totalDays = lastDay.difference(firstDay).inDays + 1;

    const double cellWidth = 48.0; // 每天格子的宽度
    final double totalWidth = totalDays * cellWidth;

    // 计算任务显示在甘特图上的条高度与行高
    final double rowHeight = 34.0;
    final double chartHeight = _tasks.length * rowHeight + 40.0; // + 标题与 padding

    // 只取当月任务用于卡片展示（但甘特图仍展示所有任务）
    final currentMonthTasks = _tasks.where((t) => t.startDate.month == _selectedDate.month || t.endDate.month == _selectedDate.month).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('项目甘特图', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
          const SizedBox(height: 12),

          // 水平可滚动区域：包含日期刻度与任务条（外层给一个固定高度，内部用 ConstrainedBox 保证宽度）
          SizedBox(
            height: chartHeight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: totalWidth, maxWidth: totalWidth),
                child: Stack(
                  children: [
                    // 日期刻度（顶部）
                    Positioned(
                      left: 0,
                      top: 0,
                      right: 0,
                      child: Row(
                        children: List.generate(totalDays, (i) {
                          final date = firstDay.add(Duration(days: i));
                          final bool isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
                          return Container(
                            width: cellWidth,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300)), color: isWeekend ? Colors.grey.shade50 : Colors.white),
                            child: Text('${date.day}', style: TextStyle(fontSize: 12, color: isWeekend ? Colors.grey : Colors.black87)),
                          );
                        }),
                      ),
                    ),

                    // 任务条区（每个任务一行）
                    Positioned(
                      left: 0,
                      top: 36,
                      child: SizedBox(
                        width: totalWidth,
                        height: _tasks.length * rowHeight,
                        child: Stack(
                          children: [
                            // 背景网格（竖线）
                            for (int i = 0; i < totalDays; i++)
                              Positioned(
                                left: i * cellWidth,
                                top: 0,
                                bottom: 0,
                                child: Container(width: 1, color: Colors.grey.shade100),
                              ),

                            // 每个任务条
                            for (int idx = 0; idx < _tasks.length; idx++)
                              Builder(builder: (context) {
                                final t = _tasks[idx];
                                final left = t.startDate.difference(firstDay).inDays * cellWidth;
                                final width = (t.endDate.difference(t.startDate).inDays + 1) * cellWidth;
                                final top = idx * rowHeight + 4.0;

                                return Positioned(
                                  left: left,
                                  top: top,
                                  child: GestureDetector(
                                    onTap: () {
                                      // 可扩展：点击高亮或弹窗
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text(t.name),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('开始：${_formatMd(t.startDate)}'),
                                              Text('结束：${_formatMd(t.endDate)}'),
                                              Text('进度：${(t.progress * 100).toInt()}%'),
                                              if (t.isMilestone) const Text('里程碑'),
                                            ],
                                          ),
                                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: width,
                                      height: rowHeight - 8,
                                      decoration: BoxDecoration(
                                        color: t.color.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: t.color.darken(0.1)),
                                        boxShadow: [BoxShadow(color: t.color.withOpacity(0.18), blurRadius: 4, offset: const Offset(0, 2))],
                                      ),
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              t.name,
                                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (t.isMilestone)
                                            Container(
                                              margin: const EdgeInsets.only(left: 6),
                                              width: 18,
                                              height: 18,
                                              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                              child: Icon(Icons.flag, size: 12, color: t.color),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 当月任务大卡片列表（只显示与当前月有交集的任务）
          Column(
            children: currentMonthTasks.map((t) => _buildMonthlyTaskCard(t)).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // body 使用 Column + Expanded 来确保垂直有约束，内部可用 SingleChildScrollView 垂直滚动
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F8),
      appBar: AppBar(
        title: const Text('项目日历与甘特图', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          _buildDateSelectorCard(),
          // Expanded 约束下面的可滚动内容高度，避免 RenderBox 错误
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildGanttChart(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      // 可扩展：浮动按钮用于新增任务
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 添加新任务逻辑
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// 数据类
class GanttTask {
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final double progress; // 0..1
  final Color color;
  final bool isMilestone;

  GanttTask({
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.progress,
    required this.color,
    this.isMilestone = false,
  });
}

/// 颜色扩展：稍微变暗（用于边框）
extension ColorUtils on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final l = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(l).toColor();
  }
}
