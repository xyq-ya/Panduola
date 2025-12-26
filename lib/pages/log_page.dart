import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'task_detail_page.dart';
import 'home_page.dart';
import 'package:http/http.dart' as http;
import '../utils/api.dart';
import 'ai_debug_page.dart';
import '../providers/user_provider.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  int? _userId;
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _userId = userProvider.id;
    if (_userId != null) _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _isLoading = true);
    try {
      final tasksResp = await http.post(
        Uri.parse(UserProvider.getApiUrl('get_tasks')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"user_id": _userId}),
      );
      final tasksData = jsonDecode(tasksResp.body)['data'] ?? [];

      final logsResp = await http.post(
        Uri.parse(UserProvider.getApiUrl('get_logs')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"user_id": _userId}),
      );
      final logsData = jsonDecode(logsResp.body)['data'] ?? [];

      setState(() {
        _tasks = List<Map<String, dynamic>>.from(tasksData);
        _logs = List<Map<String, dynamic>>.from(logsData);
      });
    } catch (e) {
      debugPrint("加载任务/日志失败: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _darken(Color color, [double amount = .2]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  Widget _noteCard(String title, String content, String time, Color tagColor, String tag,
      {VoidCallback? onTap}) {
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
                Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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

  List<Map<String, dynamic>> _mergeAndSort() {
    List<Map<String, dynamic>> combined = [];
    combined.addAll(_tasks.map((t) => {
          ...t,
          'type': 'task',
          'sort_time': t['start_time'] ?? '',
        }));
    combined.addAll(_logs.map((l) => {
          ...l,
          'type': 'log',
          'sort_time': l['create_time'] ?? '',
        }));
    combined.sort((a, b) {
      final aTime = DateTime.tryParse(a['sort_time'] ?? '') ?? DateTime(1970);
      final bTime = DateTime.tryParse(b['sort_time'] ?? '') ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });
    return combined;
  }

  Future<void> _searchItems() async {
    final keyword = await showSearch<String>(
      context: context,
      delegate: UnifiedSearchDelegate(_tasks, _logs),
    );
    if (keyword != null && keyword.isNotEmpty) {
      setState(() {});
    } else {
      _fetchAll();
    }
  }

  Future<Map<String, dynamic>?> _fetchUserInfo(int userId) async {
    try {
      final resp = await http.post(
        Uri.parse(UserProvider.getApiUrl('user_info')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"user_id": userId}),
      );
      final data = jsonDecode(resp.body);
      if (data['code'] == 0) {
        return data['data'];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("获取用户信息失败: ${data['msg']}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("获取用户信息异常: $e")));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mergedList = _mergeAndSort();
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "日志/任务记录",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        centerTitle: true,
        elevation: 1,
        actions: [
          IconButton(
            tooltip: '搜索',
            icon: const Icon(Icons.search, color: Colors.deepPurple),
            onPressed: _searchItems,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAll,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : mergedList.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        "暂无任务或日志",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                : ListView(
                    children: mergedList.map((item) {
                      if (item['type'] == 'task') {
                        Color tagColor = Colors.blue;
                        String tag = "待处理";
                        if (item['status'] == 'in_progress') {
                          tagColor = Colors.orange;
                          tag = "进行中";
                        } else if (item['status'] == 'completed') {
                          tagColor = Colors.green;
                          tag = "已完成";
                        }
                        return _noteCard(
                          item['title'] ?? '无标题',
                          item['description'] ?? '无描述',
                          item['start_time'] ?? '',
                          tagColor,
                          tag,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => TaskDetailPage(taskId: item['id'])),
                            );
                          },
                        );
                      } else {
                        return _noteCard(
                          "日志: ${item['keywords'] ?? ''}",
                          item['content'] ?? '',
                          item['create_time'] ?? '',
                          Colors.purple,
                          "日志",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => LogDetailPage(log: item)),
                            );
                          },
                        );
                      }
                    }).toList(),
                  ),
      ),
      floatingActionButton: _userId == null
    ? null
    : FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserInfo(_userId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final userInfo = snapshot.data!;
          if (userInfo['role_id'] == 5) return const SizedBox.shrink();

          return FloatingActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTaskPage(
                    userId: _userId!,
                    roleId: userInfo['role_id'],
                    teamName: userInfo['team'],
                    departmentName: userInfo['department'],
                  ),
                ),
              );
              _fetchAll(); // 返回后刷新列表
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.add),
            tooltip: "创建任务",
          );
        },
      ),
    );
  }
}

/// 搜索代理
class UnifiedSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> logs;

  UnifiedSearchDelegate(this.tasks, this.logs);

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) {
    final results = [
      ...tasks.where((t) =>
          (t['title'] ?? '').toLowerCase().contains(query.toLowerCase()) ||
          (t['description'] ?? '').toLowerCase().contains(query.toLowerCase())),
      ...logs.where((l) =>
          (l['content'] ?? '').toLowerCase().contains(query.toLowerCase()) ||
          (l['keywords'] ?? '').toLowerCase().contains(query.toLowerCase())),
    ];

    if (results.isEmpty) return const Center(child: Text("没有匹配结果"));

    return ListView(
      children: results.map((item) {
        if (item.containsKey('status')) {
          Color tagColor = Colors.blue;
          String tag = "待处理";
          if (item['status'] == 'in_progress') {
            tagColor = Colors.orange;
            tag = "进行中";
          } else if (item['status'] == 'completed') {
            tagColor = Colors.green;
            tag = "已完成";
          }
          return _buildTaskCard(item, tagColor, tag, context);
        } else {
          return _buildLogCard(item, context);
        }
      }).toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);

  Widget _buildTaskCard(Map<String, dynamic> item, Color tagColor, String tag, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskDetailPage(taskId: item['id'])),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tagColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tagColor.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['title'] ?? '无标题',
                style: TextStyle(
                    color: tagColor.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(item['description'] ?? '无描述', style: const TextStyle(fontSize: 14, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> item, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LogDetailPage(log: item)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("日志: ${item['keywords'] ?? ''}",
                style: const TextStyle(
                    color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(item['content'] ?? '', style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class LogDetailPage extends StatefulWidget {
  final Map<String, dynamic> log;
  const LogDetailPage({super.key, required this.log});

  @override
  State<LogDetailPage> createState() => _LogDetailPageState();
}

class _LogDetailPageState extends State<LogDetailPage> {
  String taskName = '';

  @override
  void initState() {
    super.initState();
    _fetchTaskName();
  }

  Future<void> _fetchTaskName() async {
    final taskId = widget.log['task_id'];
    if (taskId == null) return;

    try {
      final resp = await http.post(
        Uri.parse(UserProvider.getApiUrl('get_task_name')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'task_id': taskId}),
      );
      final data = jsonDecode(resp.body);
      if (data['code'] == 200) {
        setState(() => taskName = data['data'] ?? '');
      }
    } catch (e) {
      debugPrint("获取任务名失败: $e");
    }
  }

  Widget _buildCard({required String title, required Widget child, IconData? icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 3))],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            )
          else
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _buildInfo(String value) => Text(value, style: const TextStyle(fontSize: 16));

  // 改造后的 _buildLocation，显示经纬度和地点名称
  Widget _buildLocation(String latitude, String longitude, String locationName) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (latitude.isNotEmpty && longitude.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("纬度: $latitude", style: const TextStyle(fontSize: 16)),
                Text("经度: $longitude", style: const TextStyle(fontSize: 16)),
              ],
            ),
          const SizedBox(height: 4),
          Text("位置: $locationName", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final lat = widget.log['latitude']?.toString() ?? '';
    final lng = widget.log['longitude']?.toString() ?? '';
    final locationName = widget.log['location_name'] ?? '未知地点';

    return Scaffold(
      appBar: AppBar(
        title: const Text("日志详情"),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.log['task_id'] != null)
            _buildCard(title: "关联任务", child: _buildInfo(taskName), icon: Icons.task_alt),
          _buildCard(title: "关键词", child: _buildInfo(widget.log['keywords'] ?? ""), icon: Icons.label),
          _buildCard(title: "内容", child: _buildInfo(widget.log['content'] ?? ""), icon: Icons.description),
          if (widget.log['image_url'] != null && widget.log['image_url'].toString().isNotEmpty)
            _buildCard(
              title: "日志图片",
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  "${UserProvider.baseUrl}${widget.log['image_url']}",
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
                ),
              ),
              icon: Icons.image,
            ),
          _buildCard(title: "日志日期", child: _buildInfo(widget.log['log_date'] ?? ""), icon: Icons.calendar_today),
          _buildCard(title: "位置", child: _buildLocation(lat, lng, locationName), icon: Icons.location_on),
        ],
      ),
    );
  }
}


class AddTaskPage extends StatefulWidget {
  final int userId;
  final int roleId;
  final String? teamName;
  final String? departmentName;

  const AddTaskPage({
    super.key,
    required this.userId,
    required this.roleId,
    this.teamName,
    this.departmentName,
  });

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _totalTitleController = TextEditingController();
  final TextEditingController _totalDescController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _teams = [];
  List<Map<String, dynamic>> _users = [];
  bool _teamsRequested = false;
  bool _isLoadingTeams = false;

  List<XFile> _totalImages = [];

  List<Map<String, dynamic>> _taskBlocks = [
    {
      'title': TextEditingController(),
      'desc': TextEditingController(),
      'department': null,
      'team': null,
      'user': null,
      'images': <XFile>[],
    }
  ];

  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(days: 1));
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.roleId == 1 || widget.roleId == 2) _fetchDepartments();
    if (widget.roleId == 3) _fetchTeams();
    if (widget.roleId == 4) _fetchUsers();
  }

  // ------------------ 数据拉取 ------------------
  Future<void> _fetchDepartments() async {
    try {
      final apiUrl = UserProvider.getApiUrl('select_department');
      final res = await http.post(Uri.parse(apiUrl), headers: {'Content-Type': 'application/json'});
      final data = jsonDecode(res.body);
      if (data['code'] == 0) {
        setState(() => _departments = List<Map<String, dynamic>>.from(data['data']));
      }
    } catch (e) {
      debugPrint("加载部门失败: $e");
    }
  }

  Future<void> _fetchTeams() async {
    try {
      final dept = (widget.departmentName ?? '').trim();
      if (dept.isEmpty) return;
      setState(() => _isLoadingTeams = true);

      final apiUrl = UserProvider.getApiUrl('select_team');
      final res = await http.post(Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode({"department": dept}));
      final data = jsonDecode(res.body);
      if (data['code'] == 0) {
        setState(() => _teams = List<Map<String, dynamic>>.from(data['data']));
      }
    } catch (e) {
      debugPrint("加载团队失败: $e");
    } finally {
      if (mounted) setState(() => _isLoadingTeams = false);
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final team = (widget.teamName ?? '').trim();
      if (team.isEmpty) return;
      final apiUrl = UserProvider.getApiUrl('select_user');
      final res = await http.post(Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode({"team": team}));
      final data = jsonDecode(res.body);
      if (data['code'] == 0) {
        final filtered = List<Map<String, dynamic>>.from(data['data'])
            .where((u) => (u['id'] as int) != widget.userId)
            .toList();
        setState(() => _users = filtered);
      }
    } catch (e) {
      debugPrint("加载用户失败: $e");
    }
  }

  // ------------------ 日期选择 ------------------
  Future<void> _pickDateTime(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startTime : _endTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _startTime : _endTime),
      );
      if (time != null) {
        setState(() {
          final dt = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
          if (isStart) _startTime = dt;
          else _endTime = dt;
        });
      }
    }
  }

  // ------------------ 图片选择 ------------------
  Future<void> _pickTotalImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _totalImages = [image]; // 只保留一张图片
      });
    }
  }

  Future<void> _pickSubTaskImage(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        List<XFile> images = (_taskBlocks[index]['images'] as List<XFile>);
        images.clear();       // 清空原来的图片
        images.add(image);    // 添加新图片
      });
    }
  }

  // ------------------ 上传图片 ------------------
  Future<String?> _uploadImage(XFile file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(UserProvider.getApiUrl('upload_work_image')), // 调后端接口
      );
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final data = jsonDecode(respStr);
      if (data['code'] == 0) return data['url']; // 返回URL
      return null;
    } catch (e) {
      debugPrint("上传图片失败: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("图片上传失败")),
      );
      return null;
    }
  }


  void _removeImage(List<XFile> list, int imgIndex) => setState(() => list.removeAt(imgIndex));

  Widget _buildImagePicker(List<XFile> images, VoidCallback onAdd) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (images.isNotEmpty)
          Image.file(File(images.first.path), width: 80, height: 80, fit: BoxFit.cover),
        if (images.isNotEmpty)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: () => _removeImage(images, 0),
              child: const Icon(Icons.cancel, color: Colors.red),
            ),
          ),
        if (images.isEmpty)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 80,
              height: 80,
              color: Colors.grey.shade300,
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }

  // ------------------ 添加/删除子任务 ------------------
  void _addTaskBlock() {
    setState(() {
      _taskBlocks.add({
        'title': TextEditingController(),
        'desc': TextEditingController(),
        'department': null,
        'team': null,
        'user': null,
        'images': <XFile>[],
      });
    });
  }

  void _removeTaskBlock() {
    if (_taskBlocks.length > 1) {
      setState(() => _taskBlocks.removeLast());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("至少保留一个分发对象")),
      );
    }
  }

  // ------------------ 提交任务 ------------------
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      // ------------------ 1️⃣ 上传总任务图片（单张） ------------------
      String? totalImageUrl;
      if (_totalImages.isNotEmpty) {
        totalImageUrl = await _uploadImage(_totalImages.first);
      }

      // ------------------ 2️⃣ 创建总任务 ------------------
      String assignedType = (widget.roleId == 1 || widget.roleId == 2)
          ? 'company'
          : (widget.roleId == 3)
              ? 'dept'
              : 'team';

      final totalApiUrl = UserProvider.getApiUrl('create_task');
      final totalResp = await http.post(
        Uri.parse(totalApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': _totalTitleController.text.trim(),
          'description': _totalDescController.text.trim(),
          'creator_id': widget.userId,
          'assigned_type': assignedType,
          'assigned_id': widget.userId,
          'start_time': _startTime.toIso8601String(),
          'end_time': _endTime.toIso8601String(),
          'image_url': totalImageUrl
        }),
      );

      final totalResult = jsonDecode(totalResp.body);
      if (totalResult['code'] != 0) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("总任务创建失败: ${totalResult['msg']}")));
        return;
      }

      final totalTaskId = totalResult['data']['task_id'];

      // ------------------ 3️⃣ 循环创建子任务（也是单图） ------------------
      for (var block in _taskBlocks) {
        // 子任务单张图片
        String? subImageUrl;
        List<XFile> imgs = block['images'] as List<XFile>;
        if (imgs.isNotEmpty) {
          subImageUrl = await _uploadImage(imgs.first);
        }

        // 指派逻辑
        String subAssignedType = 'personal';
        int assignedId = widget.userId;

        if ((widget.roleId == 1 || widget.roleId == 2) && block['department'] != null) {
          subAssignedType = 'dept';
          final dept = _departments.firstWhere((d) => d['dept_name'] == block['department']);
          assignedId = dept['id'];
        } else if (widget.roleId == 3 && block['team'] != null) {
          subAssignedType = 'team';
          final team = _teams.firstWhere((t) => t['team_name'] == block['team']);
          assignedId = team['id'];
        } else if (widget.roleId == 4 && block['user'] != null) {
          final user = _users.firstWhere((u) => u['username'] == block['user']);
          assignedId = user['id'];
        }

        final subApiUrl = UserProvider.getApiUrl('create_sub_task');
        final subResp = await http.post(
          Uri.parse(subApiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': (block['title'] as TextEditingController).text.trim(),
            'description': (block['desc'] as TextEditingController).text.trim(),
            'creator_id': widget.userId,
            'assigned_type': subAssignedType,
            'assigned_id': assignedId,
            'start_time': _startTime.toIso8601String(),
            'end_time': _endTime.toIso8601String(),
            'parent_id': totalTaskId,
            'image_url': subImageUrl
          }),
        );

        final subResult = jsonDecode(subResp.body);
        if (subResult['code'] != 0) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("子任务创建失败: ${subResult['msg']}")));
        }
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("任务创建成功")));
      HomePage.homeKey.currentState?.fetchUnreadCount().then((_) {
        HomePage.homeKey.currentState?.setState(() {}); // 强制刷新
       });
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("提交任务异常: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("创建任务失败")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ------------------ UI ------------------
  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompany = widget.roleId == 1 || widget.roleId == 2;
    final isDepartment = widget.roleId == 3;
    final isTeam = widget.roleId == 4;

    if (isDepartment && _teams.isEmpty && !_teamsRequested && ((widget.departmentName ?? '').trim().isNotEmpty)) {
      _teamsRequested = true;
      Future.microtask(_fetchTeams);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("创建任务"), backgroundColor: Colors.deepPurple),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCard(
                    child: TextFormField(
                      controller: _totalTitleController,
                      decoration: const InputDecoration(labelText: "总任务标题", border: InputBorder.none),
                      validator: (v) => v == null || v.isEmpty ? "请输入总任务标题" : null,
                    ),
                  ),
                  _buildCard(
                    child: TextFormField(
                      controller: _totalDescController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: "总任务描述", border: InputBorder.none),
                    ),
                  ),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("总任务图片"),
                        const SizedBox(height: 8),
                        _buildImagePicker(_totalImages, _pickTotalImage),
                      ],
                    ),
                  ),
                  ..._taskBlocks.asMap().entries.map((entry) {
                    int index = entry.key;
                    var block = entry.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📦 分发对象 ${index + 1}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        _buildCard(
                          child: TextFormField(
                            controller: block['title'],
                            decoration: const InputDecoration(labelText: "任务标题", border: InputBorder.none),
                            validator: (v) => v == null || v.isEmpty ? "请输入任务标题" : null,
                          ),
                        ),
                        if (isCompany)
                          _buildCard(
                            child: DropdownButtonFormField<String>(
                              value: block['department'] as String?,
                              hint: const Text("选择部门"),
                              items: _departments
                                  .map((d) => DropdownMenuItem<String>(
                                        value: d['dept_name'],
                                        child: Text(d['dept_name']),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => block['department'] = v),
                              validator: (v) => v == null || v.isEmpty ? "请选择部门" : null,
                            ),
                          ),
                        if (isDepartment)
                          _buildCard(
                            child: DropdownButtonFormField<String>(
                              value: block['team'] as String?,
                              hint: Text(_isLoadingTeams
                                  ? "团队加载中..."
                                  : (_teams.isEmpty ? "暂无团队" : "选择团队")),
                              items: _teams
                                  .map((t) => DropdownMenuItem<String>(
                                        value: t['team_name'],
                                        child: Text(t['team_name']),
                                      ))
                                  .toList(),
                              onChanged: (_isLoadingTeams || _teams.isEmpty)
                                  ? null
                                  : (v) => setState(() => block['team'] = v),
                              validator: (v) => v == null || v.isEmpty ? "请选择团队" : null,
                            ),
                          ),
                        if (isTeam)
                          _buildCard(
                            child: DropdownButtonFormField<String>(
                              value: block['user'] as String?,
                              hint: const Text("选择员工"),
                              items: _users
                                  .map((u) => DropdownMenuItem<String>(
                                        value: u['username'],
                                        child: Text(u['username']),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => block['user'] = v),
                              validator: (v) => v == null || v.isEmpty ? "请选择员工" : null,
                            ),
                          ),
                        _buildCard(
                          child: TextFormField(
                            controller: block['desc'],
                            maxLines: 3,
                            decoration: const InputDecoration(labelText: "任务详情", border: InputBorder.none),
                          ),
                        ),
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("子任务图片"),
                              const SizedBox(height: 8),
                              _buildImagePicker(block['images'] as List<XFile>, () => _pickSubTaskImage(index)),
                            ],
                          ),
                        ),
                        const Divider(thickness: 1),
                      ],
                    );
                  }),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _removeTaskBlock,
                        icon: const Icon(Icons.remove),
                        label: const Text("删除分发对象"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addTaskBlock,
                        icon: const Icon(Icons.add),
                        label: const Text("增加分发对象"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildCard(
                    child: ListTile(
                      title: Text('开始时间: $_startTime'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _pickDateTime(context, true),
                    ),
                  ),
                  _buildCard(
                    child: ListTile(
                      title: Text('结束时间: $_endTime'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _pickDateTime(context, false),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text("提交任务"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}