import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../utils/api.dart';
import '../providers/user_provider.dart';

/// ✅ 日志页面
class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  int? _userId;
  int? _roleId;
  String? _departmentName;
  String? _teamName;

  @override
  void initState() {
    super.initState();
    _userId = Provider.of<UserProvider>(context, listen: false).id;
    if (_userId != null) {
      _fetchUserInfo();
    }
  }
  

  Future<void> _fetchUserInfo() async {
  try {
    if (_userId == null) {
      print("⚠️ _userId为空，无法请求 user_info");
      return;
    }

    final response = await http.post(
  Uri.parse('${Api.baseUrl()}/api/user_info'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"user_id": _userId}),
    );

    print("📡 user_info 返回状态: ${response.statusCode}");
    print("📡 user_info 返回内容: ${response.body}");

    if (response.statusCode != 200) {
      print("❌ HTTP 状态错误: ${response.statusCode}");
      return;
    }

    final decoded = jsonDecode(response.body);
    if (decoded == null || decoded is! Map) {
      print("❌ 解码失败，返回值不是有效JSON: ${response.body}");
      return;
    }

    if (decoded['code'] != 0) {
      print("❌ 接口错误: ${decoded['msg']}");
      return;
    }

    final data = decoded['data'];
    if (data == null) {
      print("❌ data字段为空");
      return;
    }

    setState(() {
      _roleId = data['role_id'];
      _departmentName = data['department'];
      _teamName = data['team'];
    });

    print("✅ 获取用户信息成功: role=$_roleId, 部门=$_departmentName, 团队=$_teamName");

  } catch (e, s) {
    print("🔥 _fetchUserInfo 异常: $e");
    print(s);
  }
}

  Color _darken(Color color, [double amount = .2]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  Widget _noteCard(String title, String content, String time, Color tagColor, String tag) {
    return Container(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAddTask = _roleId != 5 && _roleId != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("日志/任务记录",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        centerTitle: true,
        elevation: 1,
      ),
      body: ListView(
        children: [
          if (_roleId == null)
            const Center(child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ))
          else
            Column(
              children: [
                _noteCard("完成任务整理", "已将导图任务节点划分为五个子模块。", "2025-10-05 09:12",
                    Colors.purpleAccent, "工作"),
                _noteCard("系统性能优化", "修复了加载缓慢的问题，响应速度提升约30%。",
                    "2025-10-04 16:45", Colors.orangeAccent, "优化"),
              ],
            ),
        ],
      ),
      floatingActionButton: canAddTask
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTaskPage(userId: _userId!, roleId: _roleId!),
                  ),
                );
              },
              backgroundColor: Colors.purpleAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, size: 28, color: Colors.white),
            )
          : null,
    );
  }
}

class AddTaskPage extends StatefulWidget {
  final int userId;
  final int roleId;

  const AddTaskPage({super.key, required this.userId, required this.roleId});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _totalTitleController = TextEditingController();
  final TextEditingController _totalDescController = TextEditingController();

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _teams = [];
  List<Map<String, dynamic>> _users = [];

  List<Map<String, dynamic>> _taskBlocks = [
    {
      'title': TextEditingController(),
      'desc': TextEditingController(),
      'department': null,
      'team': null,
      'user': null,
    }
  ];

  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    if (widget.roleId == 1 || widget.roleId == 2) {
      _fetchDepartments();
    } else if (widget.roleId == 3) {
      _fetchTeams();
    } else if (widget.roleId == 4) {
      _fetchUsers();
    }
  }

  Future<void> _fetchDepartments() async {
    try {
      final response = await http.post(
  Uri.parse('${Api.baseUrl()}/api/select_department'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (data['code'] == 0) {
        setState(() => _departments = List<Map<String, dynamic>>.from(data['data']));
      }
    } catch (e) {
      debugPrint("加载部门失败: $e");
    }
  }

  Future<void> _fetchTeams() async {
    try {
      final response = await http.post(
  Uri.parse('${Api.baseUrl()}/api/select_team'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (data['code'] == 0) {
        setState(() => _teams = List<Map<String, dynamic>>.from(data['data']));
      }
    } catch (e) {
      debugPrint("加载团队失败: $e");
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await http.post(
  Uri.parse('${Api.baseUrl()}/api/select_user'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (data['code'] == 0) {
        setState(() => _users = List<Map<String, dynamic>>.from(data['data']));
      }
    } catch (e) {
      debugPrint("加载用户失败: $e");
    }
  }

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
          final dateTime = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
          if (isStart) _startTime = dateTime;
          else _endTime = dateTime;
        });
      }
    }
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightBlue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.lightBlue.withOpacity(0.3)),
      ),
      child: child,
    );
  }

  void _addTaskBlock() {
    setState(() {
      _taskBlocks.add({
        'title': TextEditingController(),
        'desc': TextEditingController(),
        'department': null,
        'team': null,
        'user': null,
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("任务已创建")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompany = widget.roleId == 1 || widget.roleId == 2;
    final isDepartment = widget.roleId == 3;
    final isTeam = widget.roleId == 4;

    return Scaffold(
      appBar: AppBar(
        title: const Text("创建任务"),
        backgroundColor: Colors.lightBlue,
      ),
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCard(
              child: TextFormField(
                controller: _totalTitleController,
                decoration: const InputDecoration(
                  labelText: "总任务标题",
                  border: InputBorder.none,
                ),
                validator: (v) => v == null || v.isEmpty ? "请输入总任务标题" : null,
              ),
            ),
            _buildCard(
              child: TextFormField(
                controller: _totalDescController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "总任务描述",
                  border: InputBorder.none,
                ),
              ),
            ),
            ..._taskBlocks.asMap().entries.map((entry) {
              int index = entry.key;
              var block = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("📦 分发对象 ${index + 1}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  _buildCard(
                    child: TextFormField(
                      controller: block['title'],
                      decoration: const InputDecoration(
                        labelText: "任务标题",
                        border: InputBorder.none,
                      ),
                      validator: (v) => v == null || v.isEmpty ? "请输入任务标题" : null,
                    ),
                  ),
                  if (isCompany)
                    _buildCard(
                      child: DropdownButtonFormField<String>(
                        value: block['department'] as String?,
                        hint: const Text("选择部门"),
                        items: _departments
                            .map<DropdownMenuItem<String>>(
                                (d) => DropdownMenuItem<String>(
                                      value: d['dept_name'] as String,
                                      child: Text(d['dept_name'] as String),
                                    ))
                            .toList(),
                        onChanged: (v) => setState(() => block['department'] = v),
                      ),
                    ),
                  if (isDepartment)
                    _buildCard(
                      child: DropdownButtonFormField<String>(
                        value: block['team'] as String?,
                        hint: const Text("选择团队"),
                        items: _teams
                            .map<DropdownMenuItem<String>>(
                                (t) => DropdownMenuItem<String>(
                                      value: t['team_name'] as String,
                                      child: Text(t['team_name'] as String),
                                    ))
                            .toList(),
                        onChanged: (v) => setState(() => block['team'] = v),
                      ),
                    ),
                  if (isTeam)
                    _buildCard(
                      child: DropdownButtonFormField<String>(
                        value: block['user'] as String?,
                        hint: const Text("选择员工"),
                        items: _users
                            .map<DropdownMenuItem<String>>(
                                (u) => DropdownMenuItem<String>(
                                      value: u['username'] as String,
                                      child: Text(u['username'] as String),
                                    ))
                            .toList(),
                        onChanged: (v) => setState(() => block['user'] = v),
                      ),
                    ),
                  _buildCard(
                    child: TextFormField(
                      controller: block['desc'],
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "任务详情",
                        border: InputBorder.none,
                      ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addTaskBlock,
                  icon: const Icon(Icons.add),
                  label: const Text("增加分发对象"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue[200],
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("创建任务", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}