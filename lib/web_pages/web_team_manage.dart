import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../providers/user_provider.dart';

class WebTeamManagePage extends StatefulWidget {
  const WebTeamManagePage({super.key});

  @override
  State<WebTeamManagePage> createState() => _WebTeamManagePageState();
}

class _WebTeamManagePageState extends State<WebTeamManagePage> {
  List<Map<String, dynamic>> _teams = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _teamMembers = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // 筛选状态
  String? _selectedDeptFilter;
  String? _selectedTeamFilter;

  // 添加/编辑对话框状态
  bool _showDialog = false;
  Map<String, dynamic> _editingTeam = {};
  bool _isEditing = false;

  final TextEditingController _teamNameController = TextEditingController();
  String? _selectedDeptId;
  String? _selectedLeaderId;

  // 更换团队长对话框状态
  bool _showChangeLeaderDialog = false;
  Map<String, dynamic> _changingTeam = {};
  String? _newLeaderId;

  @override
  void initState() {
    super.initState();
    _fetchTeams();
    _fetchDepartments();
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchTeams() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final url = UserProvider.getApiUrl("web/teams");
      print("🔍 请求团队数据 URL: $url");

      final resp = await http.get(Uri.parse(url));
      print("🔍 团队接口响应状态: ${resp.statusCode}");
      print("🔍 团队接口响应体: ${resp.body}");

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        if (data["code"] == 0 && data["data"] != null) {
          setState(() {
            _teams = List<Map<String, dynamic>>.from(data["data"]);
            _isLoading = false;
          });
          print("✅ 成功加载团队数据: ${_teams.length} 条记录");

          // 打印团队数据详情用于调试
          for (var team in _teams) {
            print("📋 团队详情: id=${team['id']}, name=${team['team_name']}, dept=${team['dept_name']}, leader=${team['leader_name']}");
          }
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = data["msg"] ?? "获取团队列表失败";
          });
          print("❌ 获取团队列表失败: ${data["msg"]}");
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "HTTP错误: ${resp.statusCode}";
        });
        print("❌ HTTP错误: ${resp.statusCode}");
      }
    } catch (e) {
      print("❌ 获取团队列表异常: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "网络错误: $e";
      });
    }
  }

  Future<void> _fetchDepartments() async {
    try {
      final url = UserProvider.getApiUrl("select_department");
      final resp = await http.post(Uri.parse(url));
      final data = jsonDecode(resp.body);

      if (data["code"] == 0 && data["data"] != null) {
        setState(() {
          _departments = List<Map<String, dynamic>>.from(data["data"]);
        });
        print("✅ 成功加载部门数据: ${_departments.length} 条记录");
      } else {
        print("❌ 获取部门列表失败: ${data["msg"]}");
      }
    } catch (e) {
      print("❌ 获取部门列表异常: $e");
    }
  }

  Future<void> _fetchTeamMembers(int teamId) async {
    try {
      final url = UserProvider.getApiUrl("get_team_members");
      final resp = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"team_id": teamId, "current_user_id": 0}),
      );

      final data = jsonDecode(resp.body);

      if (data["code"] == 0 && data["data"] != null) {
        setState(() {
          _teamMembers = List<Map<String, dynamic>>.from(data["data"]);
        });
        print("✅ 成功加载团队成员: ${_teamMembers.length} 人");
      } else {
        setState(() => _teamMembers = []);
        print("❌ 获取团队成员失败: ${data["msg"]}");
      }
    } catch (e) {
      print("❌ 获取团队成员异常: $e");
      setState(() => _teamMembers = []);
    }
  }

  Future<void> _fetchUsersByDepartment(int deptId) async {
    try {
      final dept = _departments.firstWhere((dept) => dept['id'] == deptId);
      final url = UserProvider.getApiUrl("web/select_user");
      final resp = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "department": dept['dept_name']
        }),
      );

      final data = jsonDecode(resp.body);

      if (data["code"] == 0 && data["data"] != null) {
        setState(() {
          _teamMembers = List<Map<String, dynamic>>.from(data["data"]);
        });
        print("✅ 成功加载部门用户: ${_teamMembers.length} 人");
      } else {
        setState(() => _teamMembers = []);
        print("❌ 获取部门用户失败: ${data["msg"]}");
      }
    } catch (e) {
      print("❌ 获取部门用户异常: $e");
      setState(() => _teamMembers = []);
    }
  }

  // 获取筛选后的团队列表
  List<Map<String, dynamic>> get _filteredTeams {
    List<Map<String, dynamic>> filtered = _teams;

    // 按部门筛选
    if (_selectedDeptFilter != null) {
      filtered = filtered.where((team) => team['dept_name'] == _selectedDeptFilter).toList();
    }

    // 按团队筛选
    if (_selectedTeamFilter != null) {
      filtered = filtered.where((team) => team['team_name'] == _selectedTeamFilter).toList();
    }

    return filtered;
  }

  void _openAddDialog() {
    setState(() {
      _showDialog = true;
      _isEditing = false;
      _editingTeam = {};
      _teamNameController.clear();
      _selectedDeptId = null;
      _selectedLeaderId = null;
      _teamMembers = [];
    });
  }

  void _openEditDialog(Map<String, dynamic> team) async {
    // 先获取该团队的成员作为团队长候选人
    await _fetchTeamMembers(team['id']);

    setState(() {
      _showDialog = true;
      _isEditing = true;
      _editingTeam = team;
      _teamNameController.text = team['team_name'] ?? '';
      _selectedDeptId = team['department_id']?.toString();
      _selectedLeaderId = team['leader_id']?.toString();
    });
  }

  void _openChangeLeaderDialog(Map<String, dynamic> team) async {
    await _fetchTeamMembers(team['id']);
    setState(() {
      _showChangeLeaderDialog = true;
      _changingTeam = team;
      _newLeaderId = team['leader_id']?.toString();
    });
  }

  void _closeDialog() {
    setState(() {
      _showDialog = false;
      _teamMembers = [];
    });
  }

  void _closeChangeLeaderDialog() {
    setState(() {
      _showChangeLeaderDialog = false;
      _teamMembers = [];
    });
  }

  Future<void> _saveTeam() async {
    final teamName = _teamNameController.text.trim();
    if (teamName.isEmpty) {
      _showSnackBar("团队名称不能为空", false);
      return;
    }

    if (_selectedDeptId == null) {
      _showSnackBar("请选择所属部门", false);
      return;
    }

    try {
      final url = UserProvider.getApiUrl(
          _isEditing ? "web/teams/update" : "web/teams/add"
      );

      final body = {
        if (_isEditing) "id": _editingTeam['id'],
        "team_name": teamName,
        "department_id": int.parse(_selectedDeptId!),
        if (_selectedLeaderId != null) "leader_id": int.parse(_selectedLeaderId!),
      };

      print("🔍 保存团队请求: $body");

      final resp = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(resp.body);

      if (data["code"] == 0) {
        _closeDialog();
        _fetchTeams();
        _showSnackBar(data["msg"] ?? "操作成功", true);
      } else {
        _showSnackBar(data["msg"] ?? "操作失败", false);
      }
    } catch (e) {
      print("❌ 保存团队失败: $e");
      _showSnackBar("网络错误，请重试", false);
    }
  }

  Future<void> _changeTeamLeader() async {
    if (_newLeaderId == null) {
      _showSnackBar("请选择新的团队长", false);
      return;
    }

    try {
      final url = UserProvider.getApiUrl("web/teams/change_leader");
      final resp = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "team_id": _changingTeam['id'],
          "new_leader_id": int.parse(_newLeaderId!),
        }),
      );

      final data = jsonDecode(resp.body);

      if (data["code"] == 0) {
        _closeChangeLeaderDialog();
        _fetchTeams();
        _showSnackBar(data["msg"] ?? "团队长更换成功", true);
      } else {
        _showSnackBar(data["msg"] ?? "更换失败", false);
      }
    } catch (e) {
      print("❌ 更换团队长失败: $e");
      _showSnackBar("网络错误，请重试", false);
    }
  }

  void _deleteTeam(Map<String, dynamic> team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("确认删除"),
        content: Text("确定要删除团队「${team['team_name']}」吗？此操作会重新计算相关任务的进度。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final url = UserProvider.getApiUrl("web/teams/delete");
                final resp = await http.post(
                  Uri.parse(url),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({"id": team['id']}),
                );

                final data = jsonDecode(resp.body);

                if (data["code"] == 0) {
                  _fetchTeams();
                  _showSnackBar(data["msg"] ?? "删除成功", true);
                } else {
                  _showSnackBar(data["msg"] ?? "删除失败", false);
                }
              } catch (e) {
                print("❌ 删除团队失败: $e");
                _showSnackBar("删除失败", false);
              }
            },
            child: const Text("确认"),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedDeptFilter = null;
      _selectedTeamFilter = null;
    });
  }

  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  void _retryFetchTeams() {
    _fetchTeams();
    _fetchDepartments();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTeams = _filteredTeams;
    final uniqueTeamNames = _teams.map((team) => team['team_name']).toSet().toList();

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "团队管理",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 20),

            // 筛选区域
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "筛选条件",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // 部门筛选
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "按部门筛选",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          value: _selectedDeptFilter,
                          items: [
                            const DropdownMenuItem(value: null, child: Text("全部部门")),
                            ..._departments.map((dept) => DropdownMenuItem(
                              value: dept['dept_name']?.toString(),
                              child: Text(dept['dept_name'] ?? ''),
                            )).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedDeptFilter = value;
                              _selectedTeamFilter = null; // 切换部门时清空团队筛选
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),

                      // 团队筛选
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "按团队筛选",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          value: _selectedTeamFilter,
                          items: [
                            const DropdownMenuItem(value: null, child: Text("全部团队")),
                            ...uniqueTeamNames.map((teamName) => DropdownMenuItem(
                              value: teamName?.toString(),
                              child: Text(teamName ?? ''),
                            )).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedTeamFilter = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),

                      // 清空筛选按钮
                      ElevatedButton(
                        onPressed: _clearFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text("清空筛选"),
                      ),

                      const Spacer(),

                      // 刷新按钮
                      IconButton(
                        onPressed: _retryFetchTeams,
                        icon: const Icon(Icons.refresh, color: Colors.blue),
                        tooltip: "刷新数据",
                      ),

                      // 新增团队按钮
                      ElevatedButton(
                        onPressed: _openAddDialog,
                        child: const Text("新增团队"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 错误信息显示
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage)),
                    TextButton(
                      onPressed: _retryFetchTeams,
                      child: const Text("重试"),
                    ),
                  ],
                ),
              ),

            // 统计信息
            if (_errorMessage.isEmpty && !_isLoading)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildStatCard("总团队数", _teams.length.toString()),
                    const SizedBox(width: 16),
                    _buildStatCard("筛选团队数", filteredTeams.length.toString()),
                    const SizedBox(width: 16),
                    _buildStatCard("有团队长",
                        _teams.where((team) => team['leader_name'] != null && team['leader_name'] != '未设置').length.toString()),
                    const SizedBox(width: 16),
                    _buildStatCard("部门数量",
                        _teams.map((team) => team['dept_name']).toSet().length.toString()),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // 团队列表
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      color: Colors.blue.shade100,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text("加载失败", style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _retryFetchTeams,
                        child: const Text("重新加载"),
                      ),
                    ],
                  ),
                )
                    : filteredTeams.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("暂无团队数据", style: TextStyle(fontSize: 16, color: Colors.grey)),
                      SizedBox(height: 8),
                      Text("请调整筛选条件或新增团队", style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                )
                    : Column(
                  children: [
                    // 表头
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 2, child: Text("团队名称", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                          Expanded(flex: 2, child: Text("所属部门", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                          Expanded(flex: 2, child: Text("团队长", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                          Expanded(flex: 2, child: Text("创建时间", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                          Expanded(flex: 2, child: Text("操作", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 团队列表
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredTeams.length,
                        itemBuilder: (context, index) {
                          final team = filteredTeams[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text(
                                  team['team_name'] ?? '未知团队',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                )),
                                Expanded(flex: 2, child: Text(
                                  team['dept_name'] ?? '未分配',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                )),
                                Expanded(flex: 2, child: Text(
                                  team['leader_name'] ?? '未设置',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: team['leader_name'] != null && team['leader_name'] != '未设置'
                                        ? Colors.green
                                        : Colors.grey,
                                    fontWeight: team['leader_name'] != null && team['leader_name'] != '未设置'
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                )),
                                Expanded(flex: 2, child: Text(
                                  team['create_time']?.toString() ?? '未知时间',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                )),
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        onPressed: () => _openEditDialog(team),
                                        icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                                        tooltip: "编辑团队",
                                      ),
                                      IconButton(
                                        onPressed: () => _openChangeLeaderDialog(team),
                                        icon: const Icon(Icons.person, color: Colors.green, size: 18),
                                        tooltip: "更换团队长",
                                      ),
                                      IconButton(
                                        onPressed: () => _deleteTeam(team),
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                        tooltip: "删除团队",
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // 添加/编辑团队对话框
        if (_showDialog)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  width: 500,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isEditing ? "编辑团队" : "新增团队",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: _closeDialog,
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _teamNameController,
                        decoration: const InputDecoration(
                          labelText: "团队名称",
                          border: OutlineInputBorder(),
                          hintText: "请输入团队名称",
                        ),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "所属部门",
                          border: OutlineInputBorder(),
                          hintText: "选择所属部门",
                        ),
                        value: _selectedDeptId,
                        items: [
                          const DropdownMenuItem(value: null, child: Text("请选择部门")),
                          ..._departments.map((dept) => DropdownMenuItem(
                            value: dept['id'].toString(),
                            child: Text(dept['dept_name'] ?? ''),
                          )),
                        ],
                        onChanged: (value) async {
                          setState(() {
                            _selectedDeptId = value;
                            _selectedLeaderId = null; // 清空团队长选择
                          });

                          // 如果选择了部门，获取该部门下的用户作为团队长候选人
                          if (value != null) {
                            await _fetchUsersByDepartment(int.parse(value));
                          } else {
                            setState(() {
                              _teamMembers = [];
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // 团队长下拉框
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "团队长",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          if (_teamMembers.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _isEditing
                                    ? "该团队暂无成员"
                                    : "请先选择部门以加载团队成员",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            )
                          else
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "选择团队长（可选）",
                              ),
                              value: _selectedLeaderId,
                              items: [
                                const DropdownMenuItem(value: null, child: Text("未设置")),
                                ..._teamMembers.map((member) => DropdownMenuItem(
                                  value: member['id'].toString(),
                                  child: Text("${member['name']} (${member['role_name'] ?? '成员'})"),
                                )),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedLeaderId = value;
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: _closeDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text("取消"),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _saveTeam,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text(_isEditing ? "保存" : "创建"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // 更换团队长对话框
        if (_showChangeLeaderDialog)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  width: 500,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "更换团队长",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "团队: ${_changingTeam['team_name']}",
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      if (_teamMembers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              "该团队暂无成员",
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "新团队长",
                            border: OutlineInputBorder(),
                          ),
                          value: _newLeaderId,
                          items: [
                            const DropdownMenuItem(value: null, child: Text("请选择团队长")),
                            ..._teamMembers.map((member) => DropdownMenuItem(
                              value: member['id'].toString(),
                              child: Text("${member['name']} (${member['role_name'] ?? '成员'})"),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _newLeaderId = value;
                            });
                          },
                        ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: _closeChangeLeaderDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text("取消"),
                          ),
                          if (_teamMembers.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _changeTeamLeader,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: const Text("确认更换"),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
          ],
        ),
      ),
    );
  }
}