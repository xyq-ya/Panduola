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

  // 编辑弹窗相关状态
  bool _showEditDialog = false;
  Map<String, dynamic> _editingUser = {};
  List<Map<String, dynamic>> _editingTeams = [];
  String? _editingDept;
  String? _editingTeam;

  // **新增**
  List<Map<String, dynamic>> _roles = [];
  int? _editingRoleId;

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
    // 更新 controllers 显示用户信息
    _controllers['username']!.text = user['username'] ?? '';
    _controllers['password']!.text = '';
    _controllers['name']!.text = user['name'] ?? '';
    _controllers['mobile']!.text = user['mobile'] ?? '';
    _controllers['email']!.text = user['email'] ?? '';

    try {
      // 获取用户详细信息
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

        // 设置原部门、原团队、原角色
        final dept = u["department"];
        final team = u["team_name"];
        final roleId = u["role_id"];

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

        // 异步获取角色列表
        List<Map<String, dynamic>> rolesListSafe = [];
        try {
          final urlRoles = UserProvider.getApiUrl("web/select_roles");
          final respRoles = await http.post(Uri.parse(urlRoles));
          final dataRolesRaw = jsonDecode(respRoles.body);

          if (dataRolesRaw is Map<String, dynamic> && dataRolesRaw["code"] == 0) {
            final dataList = dataRolesRaw["data"];
            if (dataList is List) {
              // 这里是关键，转换数据
              rolesListSafe = dataList.map<Map<String, dynamic>>((role) {
                return {
                  "id": role[0],        // 角色 ID
                  "role_name": role[1],  // 角色名称
                };
              }).toList();
            }
          }
        } catch (e) {
          print("获取角色列表失败: $e");
        }

        // 更新状态显示弹窗
        setState(() {
          _editingUser = u;
          _editingDept = dept;
          _editingTeam = team;
          _editingTeams = teamsForDept;
          _roles = rolesListSafe;
          _editingRoleId = roleId;
          _showEditDialog = true;

          // 更新 controllers 显示详细信息
          _controllers.forEach((key, ctrl) {
            ctrl.text = u[key]?.toString() ?? '';
          });

          // 调试打印
          print("------调试初值------");
          print("用户部门: '$dept'");
          print("部门列表: ${_departments.map((d) => d['dept_name']).toList()}");
          print("用户团队: '$team'");
          print("团队列表: ${teamsForDept.map((t) => t['team_name']).toList()}");
          print("用户角色ID: '$roleId'");
          print("角色列表: ${rolesListSafe.map((r) => r['role_name']).toList()}");
          print("--------------------");
        });
      }
    } catch (e) {
      print("获取用户信息失败: $e");
    }
  }

  Future<void> _saveEdit() async {
    try {
      // 更新编辑对象
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
          "team_name": _editingTeam,
          "role_id": _editingRoleId,
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
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("取消")),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(data["msg"] ?? "删除完成")));
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // 保证内容之间有间隔
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
                  ElevatedButton(onPressed: _clearSelection, child: const Text("清空选择")),
                  // 这里是新增的“新增员工”按钮
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AddUserPage();  // 在这里显示 AddUserPage 弹窗
                        },
                      );
                    },
                    child: const Text("新增员工"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[100],
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                  ),
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
                  roles: _roles,                 // 新增
                  editingDept: _editingDept,
                  editingTeam: _editingTeam,
                  editingRoleId: _editingRoleId, // 新增
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
                  onRoleChanged: (val) => setState(() => _editingRoleId = val), // 新增
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
  final List<Map<String, dynamic>> roles;
  final String? editingDept;
  final String? editingTeam;
  final int? editingRoleId;
  final Function(String?) onDeptChanged;
  final Function(String?) onTeamChanged;
  final Function(int?) onRoleChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const UserEditDialog({
    super.key,
    required this.user,
    required this.userControllers,
    required this.departments,
    required this.teams,
    required this.roles,
    required this.editingDept,
    required this.editingTeam,
    required this.editingRoleId,
    required this.onDeptChanged,
    required this.onTeamChanged,
    required this.onRoleChanged,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final safeDept = editingDept != null &&
            departments.any((d) => d['dept_name'] == editingDept)
        ? editingDept
        : null;
    final safeTeam = editingTeam != null &&
            teams.any((t) => t['team_name'] == editingTeam)
        ? editingTeam
        : null;
    final safeRoleId = editingRoleId != null &&
        roles.any((r) => r['id'] == editingRoleId)
    ? editingRoleId
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
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: "权限等级", border: OutlineInputBorder()),
              value: safeRoleId,
              items: roles
                  // 去重，防止重复 id
                  .fold<List<Map<String, dynamic>>>([], (prev, element) {
                    if (!prev.any((e) => e['id'] == element['id'])) prev.add(element);
                    return prev;
                  })
                  .map((r) => DropdownMenuItem<int>(
                        value: r['id'],
                        child: Text(r['role_name'] ?? ''),
                      ))
                  .toList(),
              onChanged: onRoleChanged,
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
// 部分代码修改如下：
class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final Map<String, TextEditingController> _controllers = {
    'username': TextEditingController(),
    'password': TextEditingController(),
    'name': TextEditingController(),
    'mobile': TextEditingController(),
    'email': TextEditingController(),
  };

  String? _selectedDept;
  String? _selectedTeam;
  int? _selectedRoleId;

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _teams = [];
  List<Map<String, dynamic>> _roles = []; // 修改为 _roles 来绑定角色列表

  bool _isTeamDropdownEnabled = false; // 控制团队下拉框是否可用

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _fetchRoles();
  }

  // 获取部门列表
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

  // 获取角色列表
  Future<void> _fetchRoles() async {
    try {
      final urlRoles = UserProvider.getApiUrl("web/select_roles");
      final respRoles = await http.post(Uri.parse(urlRoles));
      final dataRolesRaw = jsonDecode(respRoles.body);

      if (dataRolesRaw is Map<String, dynamic> && dataRolesRaw["code"] == 0) {
        final dataList = dataRolesRaw["data"];
        if (dataList is List) {
          setState(() {
            // 将角色数据绑定到 _roles
            _roles = dataList.map<Map<String, dynamic>>((role) {
              return {
                "id": role[0],        // 角色 ID
                "role_name": role[1],  // 角色名称
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      print("获取角色列表失败: $e");
    }
  }

  // 获取团队列表
  Future<void> _fetchTeams(String dept) async {
    try {
      final url = UserProvider.getApiUrl("select_team");
      final resp = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"department": dept}),
      );
      final data = jsonDecode(resp.body);
      if (data["code"] == 0 && data["data"] != null) {
        setState(() {
          _teams = List<Map<String, dynamic>>.from(data["data"]);
          _isTeamDropdownEnabled = true; // 启用团队下拉框
        });
      } else {
        setState(() {
          _teams.clear(); // 清空团队数据
          _isTeamDropdownEnabled = false; // 禁用团队下拉框
        });
      }
    } catch (e) {
      print("获取团队失败: $e");
      setState(() {
        _teams.clear();
        _isTeamDropdownEnabled = false;
      });
    }
  }

  // 保存新员工
  Future<void> _saveNewUser() async {
    try {
      final newUser = {
        "username": _controllers['username']!.text,
        "password": _controllers['password']!.text,
        "name": _controllers['name']!.text,
        "mobile": _controllers['mobile']!.text,
        "email": _controllers['email']!.text,
        "dept_name": _selectedDept,
        "team_name": _selectedTeam,
        "role_id": _selectedRoleId,
      };

      final url = UserProvider.getApiUrl("web/add_user");
      final resp = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(newUser),
      );

      final data = jsonDecode(resp.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data["msg"] ?? "新增成功")));

      if (data["code"] == 0) {
        Navigator.pop(context); // 返回上一级
      }
    } catch (e) {
      print("保存新员工失败: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16.0),
      child: Container(
        width: 600, // 设置对话框宽度，确保一致
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
              const Text(
                "新增员工",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              const SizedBox(height: 16),
              _buildTextField('用户名', _controllers['username']!),
              const SizedBox(height: 10),
              _buildTextField('密码', _controllers['password']!, obscureText: true),
              const SizedBox(height: 10),
              _buildTextField('姓名', _controllers['name']!),
              const SizedBox(height: 10),
              _buildTextField('手机号', _controllers['mobile']!),
              const SizedBox(height: 10),
              _buildTextField('邮箱', _controllers['email']!),
              const SizedBox(height: 16),
              _buildDropdown('选择部门', _departments, _selectedDept, (value) {
                setState(() {
                  _selectedDept = value;
                  _selectedTeam = null;
                  _teams.clear();
                  _isTeamDropdownEnabled = false; // 重置团队选择框
                  if (value != null) _fetchTeams(value);
                });
              }),
              const SizedBox(height: 10),
              _buildDropdown('选择团队', _teams, _selectedTeam, (value) {
                setState(() {
                  _selectedTeam = value;
                });
              }, enabled: _isTeamDropdownEnabled), // 根据获取结果启用/禁用团队选择框
              const SizedBox(height: 10),
              _buildDropdown('选择角色', _roles, _selectedRoleId, (value) {
                setState(() {
                  _selectedRoleId = value;
                });
              }),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _saveNewUser,
                    child: const Text("保存"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 创建文本框
  Widget _buildTextField(String label, TextEditingController controller, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  // 创建下拉框
  Widget _buildDropdown(
    String label,
    List<Map<String, dynamic>> items,
    dynamic selectedValue,
    Function(dynamic) onChanged, {
    bool enabled = true,
  }) {
    return DropdownButtonFormField(
      decoration: InputDecoration(
        labelText: label.isNotEmpty ? label : '请选择',
        border: const OutlineInputBorder(),
      ),
      value: selectedValue?.toString(), // 确保这里是 String 类型
      items: items.map((item) {
        return DropdownMenuItem(
          value: item["id"].toString(),  // 将 id 转换为 String
          child: Text(item["dept_name"] ?? item["team_name"] ?? item["role_name"] ?? '无数据'),
        );
      }).toList(),
      onChanged: enabled ? (value) {
        onChanged(value);
      } : null, // 只在 enabled 为 true 时才允许选择
    );
  }
}