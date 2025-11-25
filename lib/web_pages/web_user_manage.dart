import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../providers/user_provider.dart';

// ------------------ 用户管理主页面 ------------------
class WebUserManagePage extends StatefulWidget {
  const WebUserManagePage({super.key});

  @override
  State<WebUserManagePage> createState() => _WebUserManagePageState();
}

class _WebUserManagePageState extends State<WebUserManagePage> {
  // ---------------- 状态 ----------------
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _teams = [];
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _pagedUsers = [];

  String? _selectedDept;
  String? _selectedTeam;
  int _currentPage = 1;
  final int _pageSize = 10;

  bool _showEditDialog = false;
  Map<String, dynamic> _editingUser = {};
  List<Map<String, dynamic>> _editingTeams = [];
  String? _editingDept;
  String? _editingTeam;

  // TextEditingController 永远非空
  final Map<String, TextEditingController> _controllers = {
    'username': TextEditingController(),
    'password': TextEditingController(),
    'name': TextEditingController(),
    'mobile': TextEditingController(),
    'email': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _fetchAllUsers();
  }

  @override
  void dispose() {
    _controllers.forEach((_, ctrl) => ctrl.dispose());
    super.dispose();
  }

  // ---------------- API 请求 ----------------
  Future<void> _fetchDepartments() async {
    try {
      final url = UserProvider.getApiUrl("select_department");
      final resp = await http.post(Uri.parse(url));
      final data = jsonDecode(resp.body);
      if (data["code"] == 0 && data["data"] != null) {
        setState(() {
          _departments = List<Map<String, dynamic>>.from(data["data"]);
        });
      }
    } catch (e) {
      print("获取部门失败: $e");
    }
  }

  Future<void> _fetchTeams(String dept) async {
    try {
      final url = UserProvider.getApiUrl("select_team");
      final resp = await http.post(Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"department": dept}));
      final data = jsonDecode(resp.body);
      if (data["code"] == 0 && data["data"] != null) {
        setState(() {
          _teams = List<Map<String, dynamic>>.from(data["data"]);
        });
      }
    } catch (e) {
      print("获取团队失败: $e");
    }
  }

  Future<void> _fetchAllUsers({String? dept, String? team}) async {
    try {
      final url = dept == null && team == null
          ? UserProvider.getApiUrl("web/all_users")
          : UserProvider.getApiUrl("web/select_user");
      final body = <String, String>{};
      if (dept != null) body["department"] = dept;
      if (team != null) body["team"] = team;

      final resp = await http.post(Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: dept != null || team != null ? jsonEncode(body) : null);

      final data = jsonDecode(resp.body);
      if (data["code"] == 0 && data["data"] != null) {
        setState(() {
          _allUsers = List<Map<String, dynamic>>.from(data["data"]);
          _currentPage = 1;
          _updatePagedUsers();
        });
      } else {
        setState(() {
          _allUsers = [];
          _updatePagedUsers();
        });
      }
    } catch (e) {
      print("获取用户失败: $e");
      setState(() {
        _allUsers = [];
        _updatePagedUsers();
      });
    }
  }

  void _updatePagedUsers() {
    final start = (_currentPage - 1) * _pageSize;
    final end = (_currentPage * _pageSize).clamp(0, _allUsers.length);
    setState(() {
      _pagedUsers = _allUsers.sublist(start, end);
    });
  }

  void _nextPage() {
    if (_currentPage * _pageSize < _allUsers.length) {
      _currentPage++;
      _updatePagedUsers();
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      _currentPage--;
      _updatePagedUsers();
    }
  }

  // ---------------- 用户操作 ----------------
  void _openEditDialog(Map<String, dynamic> user) async {
    // 先更新 controllers 显示用户名、邮箱等
    _controllers['username']!.text = user['username'] ?? '';
    _controllers['password']!.text = '';
    _controllers['name']!.text = user['name'] ?? '';
    _controllers['mobile']!.text = user['mobile'] ?? '';
    _controllers['email']!.text = user['email'] ?? '';

    try {
      final url = UserProvider.getApiUrl("web/get_user_info");
      final resp = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": user["name"] ?? '',
          "email": user["email"] ?? '',
          "mobile": user["mobile"] ?? ''
        }),
      );
      final data = jsonDecode(resp.body);
      if (data["code"] == 0 && data["data"] != null) {
        final u = data["data"];

        // 设置原部门、原团队
        final dept = u["department"];
        final team = u["team_name"];

        // 异步获取部门对应的团队列表
        List<Map<String, dynamic>> teamsForDept = [];
        if (dept != null) {
          final urlTeams = UserProvider.getApiUrl("select_team");
          final respTeams = await http.post(
            Uri.parse(urlTeams),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"department": dept}),
          );
          final dataTeams = jsonDecode(respTeams.body);
          if (dataTeams["code"] == 0 && dataTeams["data"] != null) {
            teamsForDept = List<Map<String, dynamic>>.from(dataTeams["data"]);
          }
        }
        
        // 确保在 items 加载完毕后再打开弹窗
        setState(() {
          _editingUser = u;
          _editingDept = dept;
          _editingTeam = team;
          _editingTeams = teamsForDept;
          _showEditDialog = true;
          print("------调试初值------");
          print("用户部门: '$dept'");
          print("部门列表: ${_departments.map((d) => d['dept_name']).toList()}");
          print("用户团队: '$team'");
          print("团队列表: ${teamsForDept.map((t) => t['team_name']).toList()}");
          print("--------------------");
          // 更新 controllers 显示详细信息
          _controllers.forEach((key, ctrl) {
            ctrl.text = u[key]?.toString() ?? '';
          });
        });
      }
    } catch (e) {
      print("获取用户信息失败: $e");
    }
  }


  Future<void> _saveEdit() async {
    try {
      _controllers.forEach((key, ctrl) {
        _editingUser[key] = ctrl.text;
      });

      final url = UserProvider.getApiUrl("web/edit_user");
      final body = {
        "orig_name": _editingUser["name"] ?? '',
        "orig_email": _editingUser["email"] ?? '',
        "orig_mobile": _editingUser["mobile"] ?? '',
        "update_fields": {
          ..._editingUser,
          "dept_name": _editingDept,
          "team_name": _editingTeam
        }
      };
      final resp = await http.post(Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body));
      final data = jsonDecode(resp.body);
      _closeEditDialog();
      _fetchAllUsers();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(data["msg"] ?? "修改完成")));
    } catch (e) {
      print("编辑用户失败: $e");
    }
  }

  void _deleteUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("确认删除"),
        content: const Text(
            "删除用户会级联删除相关日志和分析，确定要删除吗？"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final url = UserProvider.getApiUrl("web/delete_user");
                  final body = {
                    "name": user["name"] ?? '',
                    "email": user["email"] ?? '',
                    "mobile": user["mobile"] ?? ''
                  };
                  final resp = await http.post(Uri.parse(url),
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode(body));
                  final data = jsonDecode(resp.body);
                  _fetchAllUsers();
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(data["msg"] ?? "删除完成")));
                } catch (e) {
                  print("删除用户失败: $e");
                }
              },
              child: const Text("确认")),
        ],
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedDept = null;
      _selectedTeam = null;
      _teams = [];
    });
    _fetchAllUsers();
  }

  void _closeEditDialog() => setState(() => _showEditDialog = false);

  // ------------------- 构建 -------------------
  @override
  Widget build(BuildContext context) {
    final totalPage = (_allUsers.length / _pageSize).ceil();
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text("员工管理",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "选择部门", border: OutlineInputBorder()),
                    value: _selectedDept,
                    items: _departments
                        .map((e) => DropdownMenuItem<String>(
                              value: e["dept_name"]?.toString(),
                              child: Text(e["dept_name"] ?? ''),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedDept = val;
                        _selectedTeam = null;
                        _teams = [];
                        if (val != null && val.isNotEmpty) {
                          _fetchTeams(val);
                          _fetchAllUsers(dept: val);
                        } else {
                          _fetchAllUsers();
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "选择团队", border: OutlineInputBorder()),
                    value: _selectedTeam,
                    items: _teams
                        .map((e) => DropdownMenuItem<String>(
                              value: e["team_name"]?.toString(),
                              child: Text(e["team_name"] ?? ''),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedTeam = val;
                        if (val != null && val.isNotEmpty) {
                          _fetchAllUsers(dept: _selectedDept, team: val);
                        } else if (_selectedDept != null) {
                          _fetchAllUsers(dept: _selectedDept);
                        } else {
                          _fetchAllUsers();
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(onPressed: _clearSelection, child: const Text("清空选择"))
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(blurRadius: 12, color: Colors.blue.shade100, offset: const Offset(0, 6))]),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.blue.shade50,
                      child: Row(
                        children: const [
                          Expanded(flex: 2, child: Text("用户名", style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 3, child: Text("邮箱", style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text("手机", style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 3, child: Text("操作", style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 4),
                    Expanded(
                      child: _pagedUsers.isEmpty
                          ? const Center(child: Text("暂无员工"))
                          : ListView.builder(
                              itemCount: _pagedUsers.length,
                              itemBuilder: (_, index) {
                                final user = _pagedUsers[index];
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Expanded(flex: 2, child: Text(user["name"] ?? '')),
                                      Expanded(flex: 3, child: Text(user["email"] ?? '')),
                                      Expanded(flex: 2, child: Text(user["mobile"] ?? '')),
                                      Expanded(
                                          flex: 3,
                                          child: Row(
                                            children: [
                                              IconButton(
                                                  onPressed: () => _openEditDialog(user),
                                                  icon: const Icon(Icons.edit, color: Colors.blue)),
                                              IconButton(
                                                  onPressed: () => _deleteUser(user),
                                                  icon: const Icon(Icons.delete, color: Colors.red)),
                                            ],
                                          ))
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(onPressed: _prevPage, icon: const Icon(Icons.arrow_back)),
                        Text("$_currentPage / $totalPage"),
                        IconButton(onPressed: _nextPage, icon: const Icon(Icons.arrow_forward)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_showEditDialog)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeEditDialog,
              child: Container(
                color: Colors.black38,
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () {}, // 防止点击穿透
                  child: UserEditDialog(
                    user: _editingUser,
                    userControllers: _controllers,
                    departments: _departments,
                    teams: _editingTeams,
                    editingDept: _editingDept,
                    editingTeam: _editingTeam,
                    onDeptChanged: (val) async {
                      if (val == null) return;

                      try {
                        final urlTeams = UserProvider.getApiUrl("select_team");
                        final respTeams = await http.post(
                          Uri.parse(urlTeams),
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({"department": val}),
                        );

                        final dataTeams = jsonDecode(respTeams.body);
                        final teamsForDept =
                            (dataTeams["code"] == 0 && dataTeams["data"] != null)
                                ? List<Map<String, dynamic>>.from(dataTeams["data"])
                                : <Map<String, dynamic>>[];

                        setState(() {
                          _editingDept = val;
                          _editingTeam = null;
                          _editingTeams = teamsForDept;
                        });
                      } catch (e) {
                        print("获取团队失败: $e");
                        setState(() {
                          _editingDept = val;
                          _editingTeam = null;
                          _editingTeams = [];
                        });
                      }
                    },
                    onTeamChanged: (val) => setState(() => _editingTeam = val),
                    onSave: _saveEdit,
                    onCancel: _closeEditDialog,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class UserEditDialog extends StatelessWidget {
  final Map<String, dynamic> user;
  final Map<String, TextEditingController> userControllers;
  final List<Map<String, dynamic>> departments;
  final List<Map<String, dynamic>> teams;
  final String? editingDept;
  final String? editingTeam;
  final Function(String?) onDeptChanged;
  final Function(String?) onTeamChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const UserEditDialog({
    super.key,
    required this.user,
    required this.userControllers,
    required this.departments,
    required this.teams,
    required this.editingDept,
    required this.editingTeam,
    required this.onDeptChanged,
    required this.onTeamChanged,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // 确保 safeDept/safeTeam 有值时才显示
    final safeDept = editingDept != null &&
            departments.any((d) => d['dept_name'] == editingDept)
        ? editingDept
        : null;
    final safeTeam = editingTeam != null &&
            teams.any((t) => t['team_name'] == editingTeam)
        ? editingTeam
        : null;

    return Container(
      width: 600,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(blurRadius: 12, color: Colors.blue.shade200)],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和关闭按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "编辑用户",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                IconButton(onPressed: onCancel, icon: const Icon(Icons.close, color: Colors.blue))
              ],
            ),
            const SizedBox(height: 10),
            // 文本字段
            ...['username', 'password', 'name', 'mobile', 'email'].map(
              (key) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextFormField(
                  controller: userControllers[key],
                  obscureText: key == 'password',
                  decoration: InputDecoration(labelText: key, border: const OutlineInputBorder()),
                  onChanged: (val) => user[key] = val,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // 部门下拉
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "部门", border: OutlineInputBorder()),
              value: safeDept,
              items: departments
                  .map((d) => d['dept_name']?.toString() ?? '')
                  .where((v) => v.isNotEmpty)
                  .toSet()
                  .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
                  .toList(),
              onChanged: onDeptChanged,
            ),
            const SizedBox(height: 10),
            // 团队下拉
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "团队", border: OutlineInputBorder()),
              value: safeTeam,
              items: teams
                  .map((t) => t['team_name']?.toString() ?? '')
                  .where((v) => v.isNotEmpty)
                  .toSet()
                  .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
                  .toList(),
              onChanged: onTeamChanged,
            ),
            const SizedBox(height: 20),
            // 保存/取消按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: const Text("保存"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onCancel,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text("取消"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}