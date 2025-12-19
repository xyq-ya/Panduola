import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../providers/user_provider.dart';

class WebDepartmentManagePage extends StatefulWidget {
  const WebDepartmentManagePage({super.key});

  @override
  State<WebDepartmentManagePage> createState() => _WebDepartmentManagePageState();
}

class _WebDepartmentManagePageState extends State<WebDepartmentManagePage> {
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _managers = [];
  bool _isLoading = true;

  // 筛选状态
  String? _selectedDeptFilter;

  // 添加/编辑对话框状态
  bool _showDialog = false;
  Map<String, dynamic> _editingDept = {};
  bool _isEditing = false;

  final TextEditingController _deptNameController = TextEditingController();
  String? _selectedManagerId;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _fetchAvailableManagers();
  }

  @override
  void dispose() {
    _deptNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchDepartments() async {
    try {
      final url = UserProvider.getApiUrl("web/departments");
      final resp = await http.get(Uri.parse(url));
      final data = jsonDecode(resp.body);

      if (data["code"] == 0 && data["data"] != null) {
        setState(() {
          _departments = List<Map<String, dynamic>>.from(data["data"]);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("获取部门列表失败: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAvailableManagers() async {
    try {
      final url = UserProvider.getApiUrl("web/available_managers");
      final resp = await http.post(Uri.parse(url));
      final data = jsonDecode(resp.body);

      if (data["code"] == 0 && data["data"] != null) {
        setState(() {
          _managers = List<Map<String, dynamic>>.from(data["data"]);
        });
      }
    } catch (e) {
      print("获取经理列表失败: $e");
    }
  }

  // 获取筛选后的部门列表
  List<Map<String, dynamic>> get _filteredDepartments {
    if (_selectedDeptFilter == null) {
      return _departments;
    }
    return _departments.where((dept) => dept['dept_name'] == _selectedDeptFilter).toList();
  }

  void _openAddDialog() {
    setState(() {
      _showDialog = true;
      _isEditing = false;
      _editingDept = {};
      _deptNameController.clear();
      _selectedManagerId = null;
    });
  }

  void _openEditDialog(Map<String, dynamic> dept) {
    setState(() {
      _showDialog = true;
      _isEditing = true;
      _editingDept = dept;
      _deptNameController.text = dept['dept_name'] ?? '';
      _selectedManagerId = dept['manager_id']?.toString();
    });
  }

  void _closeDialog() {
    setState(() {
      _showDialog = false;
    });
  }

  Future<void> _saveDepartment() async {
    final deptName = _deptNameController.text.trim();
    if (deptName.isEmpty) {
      _showSnackBar("部门名称不能为空", false);
      return;
    }

    try {
      final url = UserProvider.getApiUrl(
          _isEditing ? "web/departments/update" : "web/departments/add"
      );

      final body = {
        if (_isEditing) "id": _editingDept['id'],
        "dept_name": deptName,
        if (_selectedManagerId != null) "manager_id": int.parse(_selectedManagerId!),
      };

      final resp = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(resp.body);

      if (data["code"] == 0) {
        _closeDialog();
        _fetchDepartments();
        _showSnackBar(data["msg"] ?? "操作成功", true);
      } else {
        _showSnackBar(data["msg"] ?? "操作失败", false);
      }
    } catch (e) {
      print("保存部门失败: $e");
      _showSnackBar("网络错误，请重试", false);
    }
  }

  void _deleteDepartment(Map<String, dynamic> dept) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("确认删除"),
        content: Text("确定要删除部门「${dept['dept_name']}」吗？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final url = UserProvider.getApiUrl("web/departments/delete");
                final resp = await http.post(
                  Uri.parse(url),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({"id": dept['id']}),
                );

                final data = jsonDecode(resp.body);

                if (data["code"] == 0) {
                  _fetchDepartments();
                  _showSnackBar(data["msg"] ?? "删除成功", true);
                } else {
                  _showSnackBar(data["msg"] ?? "删除失败", false);
                }
              } catch (e) {
                print("删除部门失败: $e");
                _showSnackBar("删除失败", false);
              }
            },
            child: const Text("确认"),
          ),
        ],
      ),
    );
  }

  void _clearFilter() {
    setState(() {
      _selectedDeptFilter = null;
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

  @override
  Widget build(BuildContext context) {
    final filteredDepartments = _filteredDepartments;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "部门管理",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 20),

            // 筛选和操作按钮区域
            Row(
              children: [
                // 部门筛选下拉框
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "筛选部门",
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
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // 清空筛选按钮
                ElevatedButton(
                  onPressed: _clearFilter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text("清空筛选"),
                ),

                const Spacer(),

                // 新增部门按钮
                ElevatedButton(
                  onPressed: _openAddDialog,
                  child: const Text("新增部门"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 统计信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildStatCard("总部门数", _departments.length.toString()),
                  const SizedBox(width: 16),
                  _buildStatCard("筛选部门数", filteredDepartments.length.toString()),
                  const SizedBox(width: 16),
                  _buildStatCard("有经理部门",
                      _departments.where((dept) => dept['manager_name'] != null && dept['manager_name'] != '未设置').length.toString()),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 部门列表
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
                    : filteredDepartments.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("暂无部门数据", style: TextStyle(fontSize: 16, color: Colors.grey)),
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
                          Expanded(flex: 2, child: Text("部门名称", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                          Expanded(flex: 2, child: Text("部门经理", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                          Expanded(flex: 2, child: Text("创建时间", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                          Expanded(flex: 1, child: Text("操作", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 部门列表
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredDepartments.length,
                        itemBuilder: (context, index) {
                          final dept = filteredDepartments[index];
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
                                  dept['dept_name'] ?? '',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                )),
                                Expanded(flex: 2, child: Text(
                                  dept['manager_name'] ?? '未设置',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: dept['manager_name'] != null && dept['manager_name'] != '未设置'
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                )),
                                Expanded(flex: 2, child: Text(
                                  dept['create_time'] ?? '',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                )),
                                Expanded(
                                  flex: 1,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        onPressed: () => _openEditDialog(dept),
                                        icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                        tooltip: "编辑",
                                      ),
                                      IconButton(
                                        onPressed: () => _deleteDepartment(dept),
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        tooltip: "删除",
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

        // 添加/编辑对话框
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
                            _isEditing ? "编辑部门" : "新增部门",
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
                        controller: _deptNameController,
                        decoration: const InputDecoration(
                          labelText: "部门名称",
                          border: OutlineInputBorder(),
                          hintText: "请输入部门名称",
                        ),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "部门经理",
                          border: OutlineInputBorder(),
                          hintText: "选择部门经理",
                        ),
                        value: _selectedManagerId,
                        items: [
                          const DropdownMenuItem(value: null, child: Text("未设置")),
                          ..._managers.map((manager) => DropdownMenuItem(
                            value: manager['id'].toString(),
                            child: Text("${manager['name']} (${manager['username']})"),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedManagerId = value;
                          });
                        },
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
                            onPressed: _saveDepartment,
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