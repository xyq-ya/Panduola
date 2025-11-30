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

  String? _originalName;
  String? _originalEmail;
  String? _originalMobile;
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

  void _openEditDialog(Map<String, dynamic> user) async {
<<<<<<< Updated upstream
    // 先更新 controllers 显示用户名、邮箱等
=======
    // 保存原始的用户标识信息
    setState(() {
      _originalName = user["name"] ?? '';
      _originalEmail = user["email"] ?? '';
      _originalMobile = user["mobile"] ?? '';
    });

    print("🔹 保存原始信息: name=$_originalName, email=$_originalEmail, mobile=$_originalMobile");

    // 更新 controllers 显示用户信息 - 密码字段始终为空
>>>>>>> Stashed changes
    _controllers['username']!.text = user['username'] ?? '';
    _controllers['password']!.text = ''; // 密码字段始终为空
    _controllers['name']!.text = user['name'] ?? '';
    _controllers['mobile']!.text = user['mobile'] ?? '';
    _controllers['email']!.text = user['email'] ?? '';

    try {
      final url = UserProvider.getApiUrl("web/get_user_info");
      final resp = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": _originalName,
          "email": _originalEmail,
          "mobile": _originalMobile
        }),
      );
      final data = jsonDecode(resp.body);
      print("🔹 获取用户信息响应: $data");

      if (data["code"] == 0 && data["data"] != null) {
        final u = data["data"];

<<<<<<< Updated upstream
        // 设置原部门、原团队
=======
        // 设置部门、团队、角色信息
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
        
        // 确保在 items 加载完毕后再打开弹窗
=======

        // 异步获取角色列表
        List<Map<String, dynamic>> rolesListSafe = [];
        try {
          final urlRoles = UserProvider.getApiUrl("web/select_roles");
          final respRoles = await http.post(Uri.parse(urlRoles));
          final dataRolesRaw = jsonDecode(respRoles.body);

          if (dataRolesRaw is Map<String, dynamic> && dataRolesRaw["code"] == 0) {
            final dataList = dataRolesRaw["data"];
            if (dataList is List) {
              rolesListSafe = dataList.map<Map<String, dynamic>>((role) {
                return {
                  "id": role[0],
                  "role_name": role[1],
                };
              }).toList();
            }
          }
        } catch (e) {
          print("获取角色列表失败: $e");
        }

        // 更新状态显示弹窗
>>>>>>> Stashed changes
        setState(() {
          _editingUser = u;
          _editingDept = dept;
          _editingTeam = team;
          _editingTeams = teamsForDept;
          _showEditDialog = true;
<<<<<<< Updated upstream
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
=======
        });
      } else {
        // 如果获取详细信息失败，也显示编辑对话框，使用基本信息
        setState(() {
          _editingUser = user;
          _showEditDialog = true;
>>>>>>> Stashed changes
        });
      }
    } catch (e) {
      print("获取用户信息失败: $e");
      // 即使获取详细信息失败，也显示编辑对话框
      setState(() {
        _editingUser = user;
        _showEditDialog = true;
      });
    }
  }


  Future<void> _saveEdit() async {
    // 检查原始信息是否存在
    if (_originalName == null || _originalEmail == null || _originalMobile == null) {
      _showErrorSnackBar("用户信息不完整，请重新选择");
      return;
    }

    // 前端验证
    final email = _controllers['email']!.text.trim();
    final mobile = _controllers['mobile']!.text.trim();
    final username = _controllers['username']!.text.trim();
    final name = _controllers['name']!.text.trim();
    final password = _controllers['password']!.text.trim();

    // 邮箱格式验证
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (email.isNotEmpty && !emailRegex.hasMatch(email)) {
      _showErrorSnackBar("邮箱格式不正确");
      return;
    }

    // 手机号格式验证
    if (mobile.isNotEmpty && (mobile.length != 11 || !RegExp(r'^[0-9]+$').hasMatch(mobile))) {
      _showErrorSnackBar("手机号必须是11位数字");
      return;
    }

    // 必填字段验证
    if (username.isEmpty) {
      _showErrorSnackBar("用户名不能为空");
      return;
    }
    if (name.isEmpty) {
      _showErrorSnackBar("姓名不能为空");
      return;
    }
    if (email.isEmpty) {
      _showErrorSnackBar("邮箱不能为空");
      return;
    }
    if (mobile.isEmpty) {
      _showErrorSnackBar("手机号不能为空");
      return;
    }

    try {
<<<<<<< Updated upstream
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
=======
      // 构建更新字段 - 只包含实际有值的字段
      final updateFields = <String, dynamic>{
        'username': username,
        'name': name,
        'mobile': mobile,
        'email': email,
      };

      // 只有在新密码不为空时才更新密码
      if (password.isNotEmpty) {
        updateFields['password'] = password;
      }

      // 更新角色和团队信息
      if (_editingRoleId != null) {
        updateFields['role_id'] = _editingRoleId;
      }
      if (_editingTeam != null) {
        updateFields['team_name'] = _editingTeam;
      }

      print("🔹 原始用户标识: name=$_originalName, email=$_originalEmail, mobile=$_originalMobile");
      print("🔹 更新字段: $updateFields");

      final url = UserProvider.getApiUrl("web/edit_user");
      final body = {
        "orig_name": _originalName,
        "orig_email": _originalEmail,
        "orig_mobile": _originalMobile,
        "update_fields": updateFields,
      };

      print("🔹 发送请求体: $body");

>>>>>>> Stashed changes
      final resp = await http.post(Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body));
      final data = jsonDecode(resp.body);
<<<<<<< Updated upstream
      _closeEditDialog();
      _fetchAllUsers();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(data["msg"] ?? "修改完成")));
=======

      print("🔹 后端响应: $data");

      if (data["code"] == 0) {
        _closeEditDialog();
        _fetchAllUsers();
        _showSuccessSnackBar(data["msg"] ?? "修改成功");
      } else {
        _showErrorSnackBar(data["msg"] ?? "修改失败");
      }
>>>>>>> Stashed changes
    } catch (e) {
      print("❌ 编辑用户失败: $e");
      _showErrorSnackBar("网络错误，请重试");
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
<<<<<<< Updated upstream
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(data["msg"] ?? "删除完成")));
=======
                  if (data["code"] == 0) {
                    _showSuccessSnackBar(data["msg"] ?? "删除成功");
                  } else {
                    _showErrorSnackBar(data["msg"] ?? "删除失败");
                  }
>>>>>>> Stashed changes
                } catch (e) {
                  print("删除用户失败: $e");
                  _showErrorSnackBar("删除失败");
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

  void _closeEditDialog() {
    setState(() {
      _showEditDialog = false;
      _originalName = null;
      _originalEmail = null;
      _originalMobile = null;
      // 清空编辑状态
      _editingUser = {};
      _editingDept = null;
      _editingTeam = null;
      _editingRoleId = null;
      _editingTeams = [];
      _roles = [];
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

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
<<<<<<< Updated upstream
=======
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // 保证内容之间有间隔
>>>>>>> Stashed changes
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "选择部门", border: OutlineInputBorder()),
                    value: _selectedDept,
                    items: _departments
                        .map((e) => DropdownMenuItem<String>(
<<<<<<< Updated upstream
                              value: e["dept_name"]?.toString(),
                              child: Text(e["dept_name"] ?? ''),
                            ))
=======
                      value: e["dept_name"]?.toString(),
                      child: Text(e["dept_name"] ?? ''),
                    ))
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
                              value: e["team_name"]?.toString(),
                              child: Text(e["team_name"] ?? ''),
                            ))
=======
                      value: e["team_name"]?.toString(),
                      child: Text(e["team_name"] ?? ''),
                    ))
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
                ElevatedButton(onPressed: _clearSelection, child: const Text("清空选择"))
=======
                ElevatedButton(onPressed: _clearSelection, child: const Text("清空选择")),
                // 这里是新增的"新增员工"按钮
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
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
                    editingDept: _editingDept,
                    editingTeam: _editingTeam,
=======
                    roles: _roles,                 // 新增
                    editingDept: _editingDept,
                    editingTeam: _editingTeam,
                    editingRoleId: _editingRoleId, // 新增
>>>>>>> Stashed changes
                    onDeptChanged: (val) async {
                      if (val == null) return;

                      try {
                        final urlTeams = UserProvider.getApiUrl("select_team");
                        final respTeams = await http.post(
                          Uri.parse(urlTeams),
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({"department": val}),
                        );
<<<<<<< Updated upstream

                        final dataTeams = jsonDecode(respTeams.body);
                        final teamsForDept =
                            (dataTeams["code"] == 0 && dataTeams["data"] != null)
                                ? List<Map<String, dynamic>>.from(dataTeams["data"])
                                : <Map<String, dynamic>>[];

=======
                        final dataTeams = jsonDecode(respTeams.body);
                        final teamsForDept =
                        (dataTeams["code"] == 0 && dataTeams["data"] != null)
                            ? List<Map<String, dynamic>>.from(dataTeams["data"])
                            : <Map<String, dynamic>>[];

>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
=======
                    onRoleChanged: (val) => setState(() => _editingRoleId = val), // 新增
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
=======
    final safeRoleId = editingRoleId != null &&
        roles.any((r) => r['id'] == editingRoleId)
        ? editingRoleId
        : null;
>>>>>>> Stashed changes

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
                IconButton(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close, color: Colors.blue)
                )
              ],
            ),
            const SizedBox(height: 10),

            // 用户名
            _buildTextField('用户名', userControllers['username']!),
            const SizedBox(height: 10),

            // 密码 - 留空表示不修改
            _buildTextField(
                '密码',
                userControllers['password']!,
                obscureText: true,
                hintText: '如需修改密码请输入新密码，留空保持原密码'
            ),
            const SizedBox(height: 10),

            // 姓名
            _buildTextField('姓名', userControllers['name']!),
            const SizedBox(height: 10),

            // 手机号
            _buildMobileField('手机号', userControllers['mobile']!),
            const SizedBox(height: 10),

            // 邮箱
            _buildEmailField('邮箱', userControllers['email']!),
            const SizedBox(height: 10),

            // 部门下拉
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                  labelText: "部门",
                  border: OutlineInputBorder()
              ),
              value: safeDept,
              items: departments
                  .map((d) => DropdownMenuItem<String>(
                value: d['dept_name']?.toString(),
                child: Text(d['dept_name'] ?? ''),
              ))
                  .toList(),
              onChanged: onDeptChanged,
            ),
            const SizedBox(height: 10),

            // 团队下拉
            DropdownButtonFormField<String>(
<<<<<<< Updated upstream
              decoration: const InputDecoration(labelText: "团队", border: OutlineInputBorder()),
              value: safeTeam,
              items: teams
                  .map((t) => t['team_name']?.toString() ?? '')
                  .where((v) => v.isNotEmpty)
                  .toSet()
                  .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
=======
              decoration: const InputDecoration(
                  labelText: "团队",
                  border: OutlineInputBorder()
              ),
              value: safeTeam,
              items: teams
                  .map((t) => DropdownMenuItem<String>(
                value: t['team_name']?.toString(),
                child: Text(t['team_name'] ?? ''),
              ))
                  .toList(),
              onChanged: onTeamChanged,
            ),
            const SizedBox(height: 10),

            // 权限下拉
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                  labelText: "权限等级",
                  border: OutlineInputBorder()
              ),
              value: safeRoleId,
              items: roles
                  .map((r) => DropdownMenuItem<int>(
                value: r['id'],
                child: Text(r['role_name'] ?? ''),
              ))
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
}
=======

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      {
        bool obscureText = false,
        String? hintText
      }
      ) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildEmailField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        hintText: 'example@company.com',
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
          if (!emailRegex.hasMatch(value)) {
            return '请输入有效的邮箱地址';
          }
        }
        return null;
      },
    );
  }

  Widget _buildMobileField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      maxLength: 11,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        hintText: '13800138000',
        counterText: '',
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          if (value.length != 11 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
            return '手机号必须是11位数字';
          }
        }
        return null;
      },
    );
  }
}

// 新增员工页面
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
  List<Map<String, dynamic>> _roles = [];

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _fetchRoles();
  }

  @override
  void dispose() {
    _controllers.forEach((_, ctrl) => ctrl.dispose());
    super.dispose();
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
            _roles = dataList.map<Map<String, dynamic>>((role) {
              return {
                "id": role[0],
                "role_name": role[1],
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
        });
      }
    } catch (e) {
      print("获取团队失败: $e");
    }
  }

  // 保存新员工
  Future<void> _saveNewUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final newUser = {
        "username": _controllers['username']!.text.trim(),
        "password": _controllers['password']!.text.trim(),
        "name": _controllers['name']!.text.trim(),
        "mobile": _controllers['mobile']!.text.trim(),
        "email": _controllers['email']!.text.trim(),
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

      if (data["code"] == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["msg"] ?? "新增成功"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["msg"] ?? "新增失败"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("保存新员工失败: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("网络错误，请重试"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16.0),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(blurRadius: 12, color: Colors.blue.shade200)],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "新增员工",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                const SizedBox(height: 16),
                _buildTextField('用户名', _controllers['username']!, isRequired: true),
                const SizedBox(height: 10),
                _buildTextField('密码', _controllers['password']!, obscureText: true, isRequired: true),
                const SizedBox(height: 10),
                _buildTextField('姓名', _controllers['name']!, isRequired: true),
                const SizedBox(height: 10),
                _buildMobileField('手机号', _controllers['mobile']!, isRequired: true),
                const SizedBox(height: 10),
                _buildEmailField('邮箱', _controllers['email']!, isRequired: true),
                const SizedBox(height: 16),
                _buildDeptDropdown(),
                const SizedBox(height: 10),
                _buildTeamDropdown(),
                const SizedBox(height: 10),
                _buildRoleDropdown(),
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
      ),
    );
  }

  // 创建文本框
  Widget _buildTextField(String label, TextEditingController controller, {bool obscureText = false, bool isRequired = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return '$label不能为空';
        }
        return null;
      },
    );
  }

  // 邮箱字段
  Widget _buildEmailField(String label, TextEditingController controller, {bool isRequired = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        hintText: 'example@company.com',
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return '$label不能为空';
        }
        if (value != null && value.isNotEmpty) {
          final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
          if (!emailRegex.hasMatch(value)) {
            return '请输入有效的邮箱地址';
          }
        }
        return null;
      },
    );
  }

  // 手机号字段
  Widget _buildMobileField(String label, TextEditingController controller, {bool isRequired = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      maxLength: 11,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        hintText: '13800138000',
        counterText: '',
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return '$label不能为空';
        }
        if (value != null && value.isNotEmpty) {
          if (value.length != 11 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
            return '手机号必须是11位数字';
          }
        }
        return null;
      },
    );
  }

  // 部门下拉框
  Widget _buildDeptDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: "选择部门",
        border: OutlineInputBorder(),
      ),
      value: _selectedDept,
      items: _departments.map((dept) {
        return DropdownMenuItem<String>(
          value: dept["dept_name"]?.toString(),
          child: Text(dept["dept_name"] ?? ''),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedDept = value;
          _selectedTeam = null;
          _teams = [];
          if (value != null) {
            _fetchTeams(value);
          }
        });
      },
    );
  }

  // 团队下拉框
  Widget _buildTeamDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: "选择团队",
        border: OutlineInputBorder(),
      ),
      value: _selectedTeam,
      items: _teams.map((team) {
        return DropdownMenuItem<String>(
          value: team["team_name"]?.toString(),
          child: Text(team["team_name"] ?? ''),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedTeam = value;
        });
      },
    );
  }

  // 角色下拉框
  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<int>(
      decoration: const InputDecoration(
        labelText: "选择角色",
        border: OutlineInputBorder(),
      ),
      value: _selectedRoleId,
      items: _roles.map((role) {
        return DropdownMenuItem<int>(
          value: role["id"],
          child: Text(role["role_name"] ?? ''),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedRoleId = value;
        });
      },
    );
  }
}
>>>>>>> Stashed changes
