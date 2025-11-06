import 'package:flutter/material.dart';
<<<<<<< Updated upstream

class LogPage extends StatelessWidget {
  const LogPage({super.key});

  // 通用的颜色变暗函数（模拟 shade700）
=======
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/user_provider.dart';

/// �?日志页面
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
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoadingTasks = false;

  @override
  void initState() {
    super.initState();
    _userId = Provider.of<UserProvider>(context, listen: false).id;
    if (_userId != null) {
      _fetchUserInfo();
      _fetchTasks();
    }
  }
  
  Future<void> _fetchTasks() async {
    if (_userId == null) return;
    
    setState(() => _isLoadingTasks = true);
    
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/get_tasks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"user_id": _userId}),
      );
      
      final data = jsonDecode(response.body);
      if (data['code'] == 0 && data['data'] != null) {
        setState(() {
          _tasks = List<Map<String, dynamic>>.from(data['data']);
        });
        print("加载任务成功: ${_tasks.length} 条");
      }
    } catch (e) {
      debugPrint("加载任务失败: $e");
    } finally {
      setState(() => _isLoadingTasks = false);
    }
  }
  

  Future<void> _fetchUserInfo() async {
  try {
    if (_userId == null) {
      print("⚠️ _userId为空，无法请�?user_info");
      return;
    }

    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/api/user_info'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"user_id": _userId}),
    );

    print("📡 user_info 返回状�? ${response.statusCode}");
    print("📡 user_info 返回内容: ${response.body}");

    if (response.statusCode != 200) {
      print("�?HTTP 状态错�? ${response.statusCode}");
      return;
    }

    final decoded = jsonDecode(response.body);
    if (decoded == null || decoded is! Map) {
      print("�?解码失败，返回值不是有效JSON: ${response.body}");
      return;
    }

    if (decoded['code'] != 0) {
      print("�?接口错误: ${decoded['msg']}");
      return;
    }

    final data = decoded['data'];
    if (data == null) {
      print("�?data字段为空");
      return;
    }

    setState(() {
      _roleId = data['role_id'];
      _departmentName = data['department'];
      _teamName = data['team'];
    });

    print("�?获取用户信息成功: role=$_roleId, 部门=$_departmentName, 团队=$_teamName");

  } catch (e, s) {
    print("🔥 _fetchUserInfo 异常: $e");
    print(s);
  }
}

>>>>>>> Stashed changes
  Color _darken(Color color, [double amount = .2]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  // 日志卡片生成函数
  Widget _noteCard(
      String title, String content, String time, Color tagColor, String tag) {
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
          Text(
            title,
            style: TextStyle(
              color: _darken(tagColor, 0.18),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: _darken(tagColor, 0.18),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
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
        backgroundColor: Colors.white,
        title: const Text(
          "日志记录",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        centerTitle: true,
        elevation: 1,
      ),
<<<<<<< Updated upstream
      body: ListView(
        children: [
          _noteCard(
            "完成任务整理",
            "已将导图任务节点划分为五个子模块。",
            "2025-10-05 09:12",
            Colors.purpleAccent,
            "工作",
          ),
          _noteCard(
            "系统性能优化",
            "修复了加载缓慢的问题，响应速度提升约30%。",
            "2025-10-04 16:45",
            Colors.orangeAccent,
            "优化",
          ),
          _noteCard(
            "新增日历组件",
            "在主页中集成了自定义日历选择器。",
            "2025-10-03 11:23",
            Colors.teal,
            "开发",
          ),
          _noteCard(
            "会议记录",
            "讨论项目分支管理和版本控制。",
            "2025-10-02 14:00",
            Colors.blueAccent,
            "会议",
          ),
          _noteCard(
            "用户体验调研",
            "收集了8位用户对交互界面的反馈。",
            "2025-09-30 10:15",
            Colors.pinkAccent,
            "调研",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 可添加添加新日志逻辑
        },
        backgroundColor: Colors.purpleAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
=======
      body: RefreshIndicator(
        onRefresh: _fetchTasks,
        child: ListView(
          children: [
            if (_roleId == null || _isLoadingTasks)
              const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ))
            else if (_tasks.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(
                    "暂无任务记录",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: _tasks.map((task) {
                  // 根据任务状态选择颜色
                  Color tagColor = Colors.blue;
                  String tag = "待处理";
                  if (task['status'] == 'in_progress') {
                    tagColor = Colors.orange;
                    tag = "进行中";
                  } else if (task['status'] == 'completed') {
                    tagColor = Colors.green;
                    tag = "已完成";
                  }
                  
                  return _noteCard(
                    task['title'] ?? '无标题',
                    task['description'] ?? '无描述',
                    task['start_time'] ?? '',
                    tagColor,
                    tag,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
      floatingActionButton: canAddTask
          ? FloatingActionButton(
              onPressed: () async {
                // 调试：打印从日志页传入的团队名
                print("[FAB] LogPage _teamName: ${_teamName}");
                // 保护：团队名未就绪时不进入创建页，避免空 team 触发全量返回
                if (_teamName == null || _teamName!.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("团队信息加载中，请稍后重试")),
                  );
                  await _fetchUserInfo();
                  return;
                }
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTaskPage(
                      userId: _userId!,
                      roleId: _roleId!,
                      teamName: _teamName,
                    ),
                  ),
                );
                // 返回后刷新任务列�?                _fetchTasks();
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
  final String? teamName;

  const AddTaskPage({super.key, required this.userId, required this.roleId, this.teamName});

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
        Uri.parse('http://10.0.2.2:5000/api/select_department'),
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
        Uri.parse('http://10.0.2.2:5000/api/select_team'),
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
      // 调试：打印创建页拿到的团队名
      print("[AddTaskPage] teamName: ${widget.teamName}");
      final String teamParam = (widget.teamName ?? '').trim();
      print("[AddTaskPage] select_user body: ${jsonEncode({"team": teamParam})}");
      if (teamParam.isEmpty) {
        print("[AddTaskPage] 队伍名为空，跳过拉取用户");
        return;
      }
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/select_user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"team": teamParam}),
      );
      final data = jsonDecode(response.body);
      print("[AddTaskPage] select_user status=${response.statusCode}, body=${response.body}");
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
        const SnackBar(content: Text("至少保留一个分发对像")),
      );
    }
  }

  Future<void> _submitForm() async {
    print("🔵 ====== 开始创建任务 ======");
    print("🔵 函数被调用，开始表单验证");
    
    if (!_formKey.currentState!.validate()) {
      print("❌ 表单验证失败，无法提交");
      return;
    }
    
    print("✅ 表单验证通过，准备提交");
    
    // 显示加载提示
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      int successCount = 0;
      int failCount = 0;

      for (var block in _taskBlocks) {
        final String title = (block['title'] as TextEditingController).text.trim();
        final String desc = (block['desc'] as TextEditingController).text.trim();

        print("📝 处理任务块: title='$title', desc='$desc'");
        if (title.isEmpty) {
          print("⚠️ 跳过空标题的任务块");
          failCount++;
          continue;
        }

        String assignedType = 'personal';
        int assignedId = 0;

        if (widget.roleId == 1 || widget.roleId == 2) {
          if (block['department'] != null) {
            assignedType = 'dept';
            final dept = _departments.firstWhere((d) => d['dept_name'] == block['department']);
            assignedId = dept['id'] as int;
          }
        } else if (widget.roleId == 3) {
          if (block['team'] != null) {
            assignedType = 'team';
            final team = _teams.firstWhere((t) => t['team_name'] == block['team']);
            assignedId = team['id'] as int;
          }
        } else if (widget.roleId == 4) {
          if (block['user'] != null) {
            assignedType = 'personal';
            final user = _users.firstWhere((u) => u['username'] == block['user']);
            assignedId = user['id'] as int;
          }
        }

        if (assignedId == 0) {
          assignedType = 'personal';
          assignedId = widget.userId;
        }

        final response = await http.post(
          Uri.parse('http://10.0.2.2:5000/api/create_task'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': title,
            'description': desc,
            'creator_id': widget.userId,
            'assigned_type': assignedType,
            'assigned_id': assignedId,
            'start_time': _startTime.toIso8601String(),
            'end_time': _endTime.toIso8601String(),
          }),
        );

        print("📥 收到响应: status=${response.statusCode}, body=${response.body}");
        if (response.statusCode != 200) {
          print("❌ HTTP错误: status=${response.statusCode}");
          failCount++;
          continue;
        }

        final result = jsonDecode(response.body);
        if (result['code'] != 0) {
          print("❌ 创建任务失败: ${result['msg']}");
          failCount++;
          continue;
        }

        print("✅ 任务创建成功: id=${result['data']?['task_id']}");
        successCount++;
      }

      if (!mounted) return;
      Navigator.pop(context); // 关闭加载提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successCount > 0 ? "任务已创建" : "创建失败")),
      );
      Navigator.pop(context); // 返回上一页
    } catch (e) {
      debugPrint("提交任务异常: $e");
      if (!mounted) return;
      Navigator.pop(context); // 关闭加载提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("创建任务失败: $e")),
      );
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
                  labelText: "总任务标",
                  border: InputBorder.none,
                ),
                validator: (v) => v == null || v.isEmpty ? "请输入总任务标": null,
              ),
            ),
            _buildCard(
              child: TextFormField(
                controller: _totalDescController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "总任务描",
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
                      validator: (v) => v == null || v.isEmpty ? "请输入任务标" : null,
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
              onPressed: () {
                // 测试：立即显示 SnackBar 和打印日志
                print("🟢 ====== 按钮被点击了！======");
                print("🟢 准备调用 _submitForm() 函数");
                
                // 显示 SnackBar 确认按钮被点击
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🟢 按钮被点击了！正在提交表单...'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
                
                // 延迟一点再调用，确保 SnackBar 显示
                Future.delayed(const Duration(milliseconds: 100), () {
                  _submitForm();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // 改为红色，更容易看到变化
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("创建任务", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
>>>>>>> Stashed changes
        ),
        child: const Icon(Icons.add, size: 28, color: Colors.white),
      ),
    );
  }
}
