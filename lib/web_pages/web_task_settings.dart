import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:panduola/providers/user_provider.dart';

// ===== 任务模型 =====
class TaskItem {
  final int id;
  final String title;
  final String? startTime;
  final String? endTime;

  TaskItem({
    required this.id,
    required this.title,
    this.startTime,
    this.endTime,
  });

  static TaskItem? findById(List<TaskItem> tasks, int id) {
    for (final task in tasks) {
      if (task.id == id) return task;
    }
    return null;
  }
}

class WebTaskSettingsPage extends StatefulWidget {
  const WebTaskSettingsPage({super.key});

  @override
  State<WebTaskSettingsPage> createState() => _WebTaskSettingsPageState();
}

class _WebTaskSettingsPageState extends State<WebTaskSettingsPage> {
  List<TaskItem> _allTasks = [];
  List<int> _selectedTaskOrder = [];
  Set<int> get _selectedTaskIds => Set<int>.from(_selectedTaskOrder);
  bool _loading = true;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final tasksRes = await http.get(Uri.parse(UserProvider.getApiUrl('company_tasks')));
      final tasksJson = jsonDecode(tasksRes.body);
      if (tasksJson['code'] != 0) throw Exception(tasksJson['msg']);
      final tasks = (tasksJson['data'] as List)
          .map((e) => TaskItem(
                id: e['id'],
                title: e['title'],
                startTime: e['start_time'],
                endTime: e['end_time'],
              ))
          .toList();

      final showcaseRes = await http.get(Uri.parse(UserProvider.getApiUrl('get_company_showcase')));
      final showcaseJson = jsonDecode(showcaseRes.body);
      if (showcaseJson['code'] != 0) throw Exception(showcaseJson['msg']);
      final selectedIds = (showcaseJson['data'] as List).cast<int>();

      setState(() {
        _allTasks = tasks;
        _selectedTaskOrder = selectedIds;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: $e')),
      );
    }
  }

  void _toggleSelection(int taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskOrder.remove(taskId);
      } else {
        if (_selectedTaskOrder.length >= 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('最多只能选择10个任务')),
          );
        } else {
          _selectedTaskOrder.add(taskId);
        }
      }
    });
  }

  Future<void> _saveSettings() async {
    try {
      final response = await http.post(
        Uri.parse(UserProvider.getApiUrl('update_company_showcase')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'task_ids': _selectedTaskOrder}),
      );

      final result = jsonDecode(response.body);
      if (result['code'] == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('公司十大任务保存成功')),
        );
        _loadData();
      } else {
        throw Exception(result['msg'] ?? '未知错误');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }

  List<TaskItem> _sortedUnselectedTasks(List<TaskItem> unselected) {
    final sorted = List<TaskItem>.from(unselected)..sort((a, b) {
      if (_sortAscending) {
        return a.id.compareTo(b.id);
      } else {
        return b.id.compareTo(a.id);
      }
    });
    return sorted;
  }

  String _formatTimeRange(String? start, String? end) {
    if (start == null && end == null) return '无时间信息';
    if (start == null) return '截止: $end';
    if (end == null) return '开始: $start';
    return '$start ~ $end';
  }

  @override
  Widget build(BuildContext context) {
    final unselectedTasks = _allTasks
        .where((t) => !_selectedTaskIds.contains(t.id))
        .toList();
    final sortedUnselected = _sortedUnselectedTasks(unselectedTasks);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "公司十大任务展示设置",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.purpleAccent,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                },
                icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                label: Text(_sortAscending ? 'ID升序' : 'ID降序'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _card(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedTaskOrder.isNotEmpty) ...[
                        const Text(
                          '✅ 已选任务（最多10个）',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 12),
                        ..._selectedTaskOrder.asMap().entries.map((entry) {
                          int displayIndex = entry.key + 1;
                          int taskId = entry.value;
                          TaskItem? task = TaskItem.findById(_allTasks, taskId);
                          if (task == null) return const SizedBox.shrink();

                          return CheckboxListTile(
                            title: Text(task.title),
                            subtitle: Text(
                              '第${displayIndex}项 | ${_formatTimeRange(task.startTime, task.endTime)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            value: true,
                            onChanged: (bool? value) => _toggleSelection(task.id),
                          );
                        }).toList(),
                        const Divider(height: 32),
                      ],

                      if (sortedUnselected.isNotEmpty) ...[
                        const Text(
                          '⭕ 未选任务',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 12),
                        ...sortedUnselected.map((task) {
                          return CheckboxListTile(
                            title: Text(task.title),
                            subtitle: Text(
                              'ID:${task.id} | ${_formatTimeRange(task.startTime, task.endTime)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            value: false,
                            onChanged: (bool? value) => _toggleSelection(task.id),
                          );
                        }).toList(),
                      ],

                      const SizedBox(height: 20),
                      _button("保存公司设置"),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            color: Colors.purple.shade100,
            offset: const Offset(0, 7),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _button(String text) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.purpleAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _saveSettings,
        child: Text(text),
      ),
    );
  }
}