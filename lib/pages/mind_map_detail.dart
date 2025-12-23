import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'task_detail_page.dart';
import 'log_page.dart';

class MindMapDetailPage extends StatefulWidget {
  final String api;
  final int userId;
  final int targetUserId;

  const MindMapDetailPage({
    super.key,
    required this.api,
    required this.userId,
    required this.targetUserId,
  });

  @override
  State<MindMapDetailPage> createState() => _MindMapDetailPageState();
}

class _MindMapDetailPageState extends State<MindMapDetailPage> {
  List<dynamic>? data;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      http.Response resp;
      if (widget.api.contains('personal_top_items') || widget.api.contains('personal_logs')) {
        resp = await http.post(
          Uri.parse(widget.api),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': widget.targetUserId,
          }),
        );
      } else {
        resp = await http.get(Uri.parse(widget.api));
      }

      final result = jsonDecode(resp.body);
      if (result['code'] == 0) {
        setState(() => data = result['data'] as List<dynamic>?);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['msg'] ?? '获取数据失败')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请求异常: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _darken(Color color, [double amount = .2]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  Widget _noteCard(
      String title,
      String content,
      String timeStr,
      Color tagColor,
      String tag, {
        VoidCallback? onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: tagColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tagColor.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: tagColor.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    color: _darken(tagColor, 0.18),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 6),
            Text(content, style: const TextStyle(fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tagColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(tag,
                      style: TextStyle(
                          color: _darken(tagColor, 0.18),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> item) {
    Color tagColor = Colors.blue; // 默认待处理
    String tag = "待处理";

    // 根据任务状态选择颜色和文字
    switch (item['status']) {
      case 'in_progress':
        tagColor = Colors.orange; // 进行中
        tag = "进行中";
        break;
      case 'completed':
        tagColor = Colors.green; // 已完成
        tag = "已完成";
        break;
      case 'paused':
        tagColor = Colors.grey; // 已暂停
        tag = "已暂停";
        break;
      // 如果有其他状态，可以继续添加
    }

    String createTime = item['create_time'] ?? '';

    return _noteCard(
      item['title'] ?? '无标题',
      item['description'] ?? '无描述',
      createTime,
      tagColor, // 传入状态颜色
      tag,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskDetailPage(taskId: item['id'])),
        );
      },
    );
  }

  Widget _buildLogCard(Map<String, dynamic> item) {
    // 使用 create_time 显示完整时间
    String createTime = item['create_time'] ?? '';
    return _noteCard(
      "日志: ${item['keywords'] ?? ''}",
      item['content'] ?? '',
      createTime,
      Colors.purple,
      "日志",
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LogDetailPage(log: item)),
        );
      },
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    if (widget.api.contains('company_top_matters') ||
        widget.api.contains('company_dispatched_tasks') ||
        widget.api.contains('personal_top_items')) {
      return _buildTaskCard(item);
    } else if (widget.api.contains('personal_logs')) {
      return _buildLogCard(item);
    } else {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.all(14),
        color: Colors.grey.withOpacity(0.08),
        child: Text(item.toString()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('详情'), backgroundColor: Colors.deepPurple),
      body: Stack(
        children: [
          // 主体内容：任务列表
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : (data == null || data!.isEmpty)
                  ? const Center(child: Text('暂无数据'))
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: data!.map((item) {
                        return _buildItemCard(item as Map<String, dynamic>);
                      }).toList(),
                    ),

          // 底部按钮（仅当满足条件时显示）
          if (widget.userId == widget.targetUserId &&
              widget.api.contains('personal_top_items'))
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    // 跳转到编辑展示项页面
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditShowcasePage(
                          userId: widget.userId,
                          targetUserId: widget.targetUserId,
                          initialSelectedIds: [], // 可传已选项
                        ),
                      ),
                    );

                    if (result != null) {
                      List<int> selectedIds = result as List<int>;

                      // 限制最多10个
                      if (selectedIds.length > 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('最多只能选择10个展示项')),
                        );
                        return;
                      }

                      // 调接口保存到后端
                      try {
                        final resp = await http.post(
                          Uri.parse(UserProvider.getApiUrl('update_personal_showcase')),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'user_id': widget.userId,
                            'task_ids': selectedIds,
                          }),
                        );

                        final resultData = jsonDecode(resp.body);
                        if (resultData['code'] == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('保存成功')),
                          );
                          _fetchData(); // 重新加载数据
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(resultData['msg'] ?? '保存失败')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('请求异常: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple[300], // 浅色
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '修改个人展示项',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class EditShowcasePage extends StatefulWidget {
  final int userId;          // 当前登录用户 ID
  final int targetUserId;    // 被展示人的 ID
  final List<int> initialSelectedIds; // 初始已选任务ID

  const EditShowcasePage({
    super.key,
    required this.userId,
    required this.targetUserId,
    this.initialSelectedIds = const [],
  });

  @override
  State<EditShowcasePage> createState() => _EditShowcasePageState();
}

class _EditShowcasePageState extends State<EditShowcasePage> {
  List<Map<String, dynamic>> tasks = [];  // 所有可选任务
  late List<int> selectedIds;             // 已选任务ID
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedIds = List<int>.from(widget.initialSelectedIds);
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final resp = await http.post(
        Uri.parse(UserProvider.getApiUrl('get_tasks')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': widget.targetUserId}),
      );

      final result = jsonDecode(resp.body);
      if (result['code'] == 0) {
        final List<dynamic> list = result['data'] ?? [];
        setState(() => tasks = list.cast<Map<String, dynamic>>());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['msg'] ?? '获取任务失败')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请求异常: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleSelect(int taskId) {
    setState(() {
      if (selectedIds.contains(taskId)) {
        selectedIds.remove(taskId);
      } else {
        if (selectedIds.length >= 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('最多只能选择10个展示项')),
          );
          return;
        }
        selectedIds.add(taskId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('修改个人展示项'), backgroundColor: Colors.deepPurple),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 已选展示项（可拖动顺序）
                Expanded(
                  child: ReorderableListView(
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final id = selectedIds.removeAt(oldIndex);
                        selectedIds.insert(newIndex, id);
                      });
                    },
                    children: selectedIds.map((taskId) {
                      final task = tasks.firstWhere((t) => t['id'] == taskId, orElse: () => {});
                      return ListTile(
                        key: ValueKey(taskId),
                        title: Text(task['title'] ?? '无标题'),
                        subtitle: Text(task['description'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _toggleSelect(taskId),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(),
                // 可选任务列表
                Expanded(
                  child: ListView(
                    children: tasks.where((t) => !selectedIds.contains(t['id'])).map((task) {
                      return ListTile(
                        title: Text(task['title'] ?? '无标题'),
                        subtitle: Text(task['description'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          onPressed: () => _toggleSelect(task['id']),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                // 保存展示项按钮（EditShowcasePage）
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, selectedIds);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple[300], // 浅色
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('保存展示项', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
    );
  }
}