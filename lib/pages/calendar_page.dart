import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/user_provider.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  int? _userId;
  List<GanttTask> _tasks = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _userId = Provider.of<UserProvider>(context, listen: false).id;
    print('页面获取的用户 id：$_userId');
    _fetchTaskData();
  }

  // 从后端获取任务数据
  Future<void> _fetchTaskData() async {
    if (_userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/get_user_tasks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': _userId}),
      );

      print('任务数据响应: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 0) {
          final List<dynamic> taskData = data['data'] ?? [];
          setState(() {
            _tasks = taskData.map((item) => GanttTask(
              id: item['id'] ?? 0,
              name: item['name'] ?? '未命名任务',
              startDate: DateTime.parse(item['start_date'] ?? DateTime.now().toString()),
              endDate: DateTime.parse(item['end_date'] ?? DateTime.now().add(Duration(days: 1)).toString()),
              progress: (item['progress'] ?? 0.0).toDouble(),
              color: _parseColor(item['color']),
              isMilestone: item['is_milestone'] ?? false,
              status: item['status'] ?? 'pending',
              assigneeName: item['assignee_name'] ?? '',
              creatorName: item['creator_name'] ?? '',
              description: item['description'] ?? '',
            )).toList();
            _isLoading = false;
          });
          print('成功加载 ${_tasks.length} 个任务');
        } else {
          throw Exception('API错误: ${data['msg']}');
        }
      } else {
        throw Exception('HTTP错误: ${response.statusCode}');
      }
    } catch (e) {
      print('获取任务数据失败: $e');
      setState(() {
        _isLoading = false;
        // 如果获取失败，使用示例数据
        _tasks = _getFallbackTasks();
      });
    }
  }

  // 解析颜色字符串
  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) {
      return const Color(0xFF1976D2); // 默认蓝色
    }

    try {
      // 处理 #FF0000 格式
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
      }
      return const Color(0xFF1976D2);
    } catch (e) {
      return const Color(0xFF1976D2);
    }
  }

  // 备用数据（当API不可用时）
  List<GanttTask> _getFallbackTasks() {
    return [
      GanttTask(
        id: 1,
        name: '公司年度项目规划',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
        progress: 0.3,
        color: const Color(0xFF1976D2),
        isMilestone: false,
        status: 'pending',
        assigneeName: '超级管理员',
        creatorName: '超级管理员',
        description: '制定公司年度技术发展路线图和项目规划',
      ),
      GanttTask(
        id: 2,
        name: '技术部季度目标',
        startDate: DateTime(2024, 1, 15),
        endDate: DateTime(2024, 3, 31),
        progress: 0.6,
        color: const Color(0xFF388E3C),
        isMilestone: false,
        status: 'pending',
        assigneeName: '王伟',
        creatorName: '超级管理员',
        description: '技术部本季度重点工作和目标设定',
      ),
      GanttTask(
        id: 3,
        name: '前端架构升级',
        startDate: DateTime(2024, 2, 1),
        endDate: DateTime(2024, 6, 30),
        progress: 0.2,
        color: const Color(0xFFFF9800),
        isMilestone: false,
        status: 'pending',
        assigneeName: '王伟',
        creatorName: '王伟',
        description: '将现有前端架构从Vue2升级到Vue3',
      ),
    ];
  }

  // 小工具：格式化年月
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
      helpText: '选择查看月份',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  // 刷新数据
  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _fetchTaskData();
  }

  // 年月选择卡片
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
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新数据',
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

  // 大尺寸任务卡片
  Widget _buildMonthlyTaskCard(GanttTask t) {
    // 只显示当前月份的任务
    if (t.startDate.month != _selectedDate.month && t.endDate.month != _selectedDate.month) {
      return const SizedBox.shrink();
    }

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
          Row(
            children: [
              Expanded(
                child: Text(
                  t.name,
                  style: TextStyle(
                    color: t.color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(t.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusText(t.status),
                  style: TextStyle(
                    color: _getStatusColor(t.status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_formatMd(t.startDate)} - ${_formatMd(t.endDate)}',
            style: const TextStyle(color: Colors.black54),
          ),
          if (t.assigneeName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '负责人: ${t.assigneeName}',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
          if (t.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              t.description,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          // 查看详情按钮
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
                        Text('状态：${_getStatusText(t.status)}'),
                        if (t.assigneeName.isNotEmpty) Text('负责人：${t.assigneeName}'),
                        if (t.creatorName.isNotEmpty) Text('创建人：${t.creatorName}'),
                        if (t.description.isNotEmpty) Text('描述：${t.description}'),
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

  // 获取状态颜色
  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  // 获取状态文本
  String _getStatusText(String status) {
    switch (status) {
      case 'completed': return '已完成';
      case 'in_progress': return '进行中';
      case 'pending': return '未开始';
      default: return '未知';
    }
  }

  // 甘特图组件
  Widget _buildGanttChart() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tasks.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          children: [
            Icon(Icons.calendar_today, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无任务数据', style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 8),
            Text('您还没有被分配或创建任何任务', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }

    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final totalDays = lastDay.difference(firstDay).inDays + 1;

    const double cellWidth = 48.0;
    final double totalWidth = totalDays * cellWidth;
    final double rowHeight = 34.0;
    final double chartHeight = _tasks.length * rowHeight + 40.0;

    // 当前月份的任务（用于卡片显示）
    final currentMonthTasks = _tasks.where((t) =>
    t.startDate.month == _selectedDate.month ||
        t.endDate.month == _selectedDate.month
    ).toList();

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
          Row(
            children: [
              const Text('任务甘特图', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              const SizedBox(width: 8),
              Chip(
                label: Text('${_tasks.length} 个任务'),
                backgroundColor: Colors.blue.shade50,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 水平可滚动甘特图
          SizedBox(
            height: chartHeight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: totalWidth, maxWidth: totalWidth),
                child: Stack(
                  children: [
                    // 日期刻度
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
                            decoration: BoxDecoration(
                                border: Border(right: BorderSide(color: Colors.grey.shade300)),
                                color: isWeekend ? Colors.grey.shade50 : Colors.white
                            ),
                            child: Text('${date.day}', style: TextStyle(
                                fontSize: 12,
                                color: isWeekend ? Colors.grey : Colors.black87
                            )),
                          );
                        }),
                      ),
                    ),

                    // 任务条
                    Positioned(
                      left: 0,
                      top: 36,
                      child: SizedBox(
                        width: totalWidth,
                        height: _tasks.length * rowHeight,
                        child: Stack(
                          children: [
                            // 背景网格
                            for (int i = 0; i < totalDays; i++)
                              Positioned(
                                left: i * cellWidth,
                                top: 0,
                                bottom: 0,
                                child: Container(width: 1, color: Colors.grey.shade100),
                              ),

                            // 任务条
                            for (int idx = 0; idx < _tasks.length; idx++)
                              Builder(builder: (context) {
                                final t = _tasks[idx];
                                final startDiff = t.startDate.difference(firstDay).inDays;
                                final endDiff = t.endDate.difference(firstDay).inDays;

                                // 确保任务条在可见范围内
                                final left = startDiff.clamp(0, totalDays - 1) * cellWidth;
                                final width = ((endDiff - startDiff + 1).clamp(1, totalDays)) * cellWidth;
                                final top = idx * rowHeight + 4.0;

                                return Positioned(
                                  left: left,
                                  top: top,
                                  child: GestureDetector(
                                    onTap: () {
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
                                              Text('状态：${_getStatusText(t.status)}'),
                                              if (t.assigneeName.isNotEmpty) Text('负责人：${t.assigneeName}'),
                                            ],
                                          ),
                                          actions: [TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('关闭')
                                          )],
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
                                        boxShadow: [BoxShadow(
                                            color: t.color.withOpacity(0.18),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2)
                                        )],
                                      ),
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              t.name,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.only(left: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.9),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${(t.progress * 100).toInt()}%',
                                              style: TextStyle(
                                                color: t.color,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
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

          // 当月任务卡片列表
          if (currentMonthTasks.isNotEmpty) ...[
            const Text('当月任务', style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB)
            )),
            const SizedBox(height: 8),
            Column(
              children: currentMonthTasks.map((t) => _buildMonthlyTaskCard(t)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F8),
      appBar: AppBar(
        title: const Text('任务日历与甘特图', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: '刷新数据',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelectorCard(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildGanttChart(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 数据类
class GanttTask {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final double progress; // 0..1
  final Color color;
  final bool isMilestone;
  final String status;
  final String assigneeName;
  final String creatorName;
  final String description;

  GanttTask({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.progress,
    required this.color,
    this.isMilestone = false,
    required this.status,
    required this.assigneeName,
    required this.creatorName,
    required this.description,
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