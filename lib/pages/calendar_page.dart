import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'task_detail_page.dart';
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
  String _currentView = 'month';

  @override
  void initState() {
    super.initState();
    _userId = Provider.of<UserProvider>(context, listen: false).id;
    print('页面获取的用户 id：$_userId');
    _fetchTaskData();
  }

  // 获取导航单位文本
  String _getNavigationUnit() {
    switch (_currentView) {
      case 'day':
        return '天';
      case 'week':
        return '周';
      case 'month':
        return '月';
      default:
        return '月';
    }
  }

  // 从后端获取任务数据
  Future<void> _fetchTaskData() async {
    if (_userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final apiUrl = UserProvider.getApiUrl('get_user_tasks');
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': _userId}),
      );

      print('任务数据响应: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 0) {
          final List<dynamic> taskData = data['data'] ?? [];

          setState(() {
            _tasks = taskData.map((item) {
              final assignedType = item['assigned_type'];
              print('映射任务 "${item['name']}": assigned_type = "$assignedType"');

              return GanttTask(
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
                assignedType: assignedType?.toString() ?? 'personal',
              );
            }).toList();
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
        _tasks = [];
      });
    }
  }

  // 根据 assigned_type 获取任务类型显示文本
  String _getTaskTypeDisplayText(String assignedType) {
    switch (assignedType.toLowerCase()) {
      case 'personal':
        return '个人任务';
      case 'team':
        return '团队任务';
      default:
        return '未知任务';
    }
  }

  // 根据 assigned_type 获取任务类型颜色
  Color _getTaskTypeColor(String assignedType) {
    switch (assignedType.toLowerCase()) {
      case 'personal':
        return Colors.orange;
      case 'team':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // 解析颜色字符串
  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) {
      return const Color(0xFF1976D2);
    }

    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
      }
      return const Color(0xFF1976D2);
    } catch (e) {
      return const Color(0xFF1976D2);
    }
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

  // 小工具：格式化星期
  String _formatWeekday(DateTime d) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[d.weekday - 1];
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2018),
      lastDate: DateTime(2035),
      helpText: '选择查看日期',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // 切换视图
  void _switchView(String view) {
    setState(() {
      _currentView = view;
    });
  }

  // 导航到前一天/周/月
  void _navigatePrevious() {
    setState(() {
      switch (_currentView) {
        case 'day':
          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
          break;
        case 'week':
          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
          break;
        case 'month':
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
          break;
      }
    });
  }

  // 导航到后一天/周/月
  void _navigateNext() {
    setState(() {
      switch (_currentView) {
        case 'day':
          _selectedDate = _selectedDate.add(const Duration(days: 1));
          break;
        case 'week':
          _selectedDate = _selectedDate.add(const Duration(days: 7));
          break;
        case 'month':
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
          break;
      }
    });
  }

  // 回到今天
  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  // 刷新数据
  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _fetchTaskData();
  }

  // 获取当前视图的标题
  String _getViewTitle() {
    switch (_currentView) {
      case 'day':
        return '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日';
      case 'week':
        final firstDay = _getFirstDayOfWeek(_selectedDate);
        final lastDay = firstDay.add(const Duration(days: 6));
        return '${firstDay.month}月${firstDay.day}日 - ${lastDay.month}月${lastDay.day}日';
      case 'month':
        return _formatYearMonth(_selectedDate);
      default:
        return _formatYearMonth(_selectedDate);
    }
  }

  // 获取一周的第一天（周一）
  DateTime _getFirstDayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  // 构建甘特图
  Widget _buildGanttChart() {
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final totalDays = lastDay.difference(firstDay).inDays + 1;

    const double cellWidth = 48.0;
    final double totalWidth = totalDays * cellWidth;
    final double rowHeight = 34.0;
    final double chartHeight = _tasks.length * rowHeight + 60.0;

    // 当前月份在甘特图中显示的任务数
    final currentMonthGanttTasks = _tasks.where((t) {
      final taskStart = t.startDate.isAfter(firstDay) ? t.startDate : firstDay;
      final taskEnd = t.endDate.isBefore(lastDay) ? t.endDate : lastDay;
      return !(taskStart.isAfter(lastDay) || taskEnd.isBefore(firstDay));
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              const Text('月度甘特图', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              const SizedBox(width: 8),
              Chip(
                label: Text('${currentMonthGanttTasks.length} 个任务'),
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
                          final bool isToday = date.year == DateTime.now().year &&
                              date.month == DateTime.now().month &&
                              date.day == DateTime.now().day;
                          return Container(
                            width: cellWidth,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                border: Border(right: BorderSide(color: Colors.grey.shade300)),
                                color: isToday ? Colors.blue.shade50 : (isWeekend ? Colors.grey.shade50 : Colors.white)
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${date.day}', style: TextStyle(
                                  fontSize: 12,
                                  color: isToday ? Colors.blue : (isWeekend ? Colors.grey : Colors.black87),
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                )),
                                if (isToday) Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
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
                                DateTime visibleStart = t.startDate.isAfter(firstDay) ? t.startDate : firstDay;
                                DateTime visibleEnd = t.endDate.isBefore(lastDay) ? t.endDate : lastDay;

                                if (visibleStart.isAfter(lastDay) || visibleEnd.isBefore(firstDay)) {
                                  return const SizedBox.shrink();
                                }

                                int startDay = visibleStart.difference(firstDay).inDays;
                                int endDay = visibleEnd.difference(firstDay).inDays;
                                int duration = endDay - startDay + 1;

                                if (startDay < 0) startDay = 0;
                                if (startDay >= totalDays) return const SizedBox.shrink();
                                if (duration <= 0) duration = 1;
                                if (startDay + duration > totalDays) {
                                  duration = totalDays - startDay;
                                }

                                final left = startDay * cellWidth;
                                final width = duration * cellWidth;
                                final top = idx * rowHeight + 4.0;

                                return Positioned(
                                  left: left.toDouble(),
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
                                              Text('任务类型：${_getTaskTypeDisplayText(t.assignedType)}'),
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
                                      width: width.toDouble(),
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
        ],
      ),
    );
  }
// 视图选择器卡片
  Widget _buildViewSelectorCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          // 视图切换按钮行
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildViewButton('月视图', 'month', Icons.calendar_view_month),
                      const SizedBox(width: 8),
                      _buildViewButton('周视图', 'week', Icons.view_week),
                      const SizedBox(width: 8),
                      _buildViewButton('日视图', 'day', Icons.view_day),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 导航控制行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 左侧导航按钮
              Row(
                children: [
                  IconButton(
                    onPressed: _navigatePrevious,
                    icon: const Icon(Icons.chevron_left),
                    tooltip: '上一${_getNavigationUnit()}',
                  ),
                  TextButton(
                    onPressed: _goToToday,
                    child: Text(_getTodayText()), // 修改这里
                  ),
                  IconButton(
                    onPressed: _navigateNext,
                    icon: const Icon(Icons.chevron_right),
                    tooltip: '下一${_getNavigationUnit()}',
                  ),
                ],
              ),

              // 刷新按钮
              IconButton(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh),
                tooltip: '刷新数据',
              ),
            ],
          ),
        ],
      ),
    );
  }

// 获取"今天"按钮的文本
  String _getTodayText() {
    switch (_currentView) {
      case 'day':
        return '今天';
      case 'week':
        return '本周';
      case 'month':
        return '本月';
      default:
        return '今天';
    }
  }

  // 日期选择器卡片
  Widget _buildDateSelectorCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, color: Colors.deepPurple),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getViewTitle(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.date_range),
                label: const Text('选择日期'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建视图切换按钮
  Widget _buildViewButton(String text, String view, IconData icon) {
    final isActive = _currentView == view;
    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      child: ElevatedButton(
        onPressed: () => _switchView(view),
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.deepPurple : Colors.grey.shade100,
          foregroundColor: isActive ? Colors.white : Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // 构建任务卡片
  Widget _buildTaskCard(GanttTask t) {
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
              Container(
                constraints: const BoxConstraints(maxWidth: 80),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTaskTypeColor(t.assignedType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getTaskTypeDisplayText(t.assignedType),
                  style: TextStyle(
                    color: _getTaskTypeColor(t.assignedType),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.name,
                  style: TextStyle(
                    color: t.color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxWidth: 60),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(t.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusText(t.status),
                  style: TextStyle(
                    color: _getStatusColor(t.status),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 4),
          Text(
            _getTaskTypeDescription(t.assignedType),
            style: TextStyle(
              color: _getTaskTypeColor(t.assignedType),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskDetailPage(taskId: t.id),
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

  // 获取任务类型描述
  String _getTaskTypeDescription(String assignedType) {
    switch (assignedType.toLowerCase()) {
      case 'personal':
        return '📋 个人任务';
      case 'team':
        return '👥 团队共享任务';
      default:
        return '📋 任务';
    }
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

  // 构建任务详细列表
  Widget _buildTaskList() {
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

    List<GanttTask> currentTasks = [];
    String title = '';

    switch (_currentView) {
      case 'month':
        final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
        final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
        currentTasks = _tasks.where((t) {
          return (t.startDate.year == _selectedDate.year && t.startDate.month == _selectedDate.month) ||
              (t.endDate.year == _selectedDate.year && t.endDate.month == _selectedDate.month) ||
              (t.startDate.isBefore(firstDay) && t.endDate.isAfter(lastDay)) ||
              (t.startDate.isBefore(lastDay) && t.endDate.isAfter(firstDay));
        }).toList();
        title = '当月任务 (${currentTasks.length})';
        break;
      case 'week':
        final firstDay = _getFirstDayOfWeek(_selectedDate);
        final lastDay = firstDay.add(const Duration(days: 6));
        currentTasks = _tasks.where((t) {
          return !(t.endDate.isBefore(firstDay) || t.startDate.isAfter(lastDay));
        }).toList();
        title = '本周任务 (${currentTasks.length})';
        break;
      case 'day':
        final dayStart = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0);
        final dayEnd = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59);
        currentTasks = _tasks.where((t) {
          return !(t.endDate.isBefore(dayStart) || t.startDate.isAfter(dayEnd));
        }).toList();
        title = '今日任务 (${currentTasks.length})';
        break;
    }

    if (currentTasks.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.event_available, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _currentView == 'day' ? '今日暂无任务' :
              _currentView == 'week' ? '本周暂无任务' : '当月暂无任务',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (_currentView == 'day') ...[
              const SizedBox(height: 8),
              const Text('好好享受轻松的一天吧！', style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB)
          )),
          const SizedBox(height: 8),
          Column(
            children: currentTasks.map((t) => _buildTaskCard(t)).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F8),
      appBar: AppBar(
        title: const Text('任务日历', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          // 上方：甘特图（固定显示）
          _buildGanttChart(),

          // 中间：日期选择和视图切换
          _buildDateSelectorCard(),
          _buildViewSelectorCard(),

          // 下方：任务详细列表（根据视图切换）
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                child: _buildTaskList(),
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
  final double progress;
  final Color color;
  final bool isMilestone;
  final String status;
  final String assigneeName;
  final String creatorName;
  final String description;
  final String assignedType;

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
    required this.assignedType,
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