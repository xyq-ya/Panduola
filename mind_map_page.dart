import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MindMapPage extends StatefulWidget {
  const MindMapPage({super.key});

  @override
  State<MindMapPage> createState() => _MindMapPageState();
}

class _MindMapPageState extends State<MindMapPage> {
  int? _userId;
  int? _roleId;
  String? selectedDepartment;
  String? selectedTeam;
  String? selectedEmployee;

  List<String> departments = [];
  List<String> teams = [];
  List<String> employees = [];

  // 数据源
  List<String> companyMatters = [];
  List<Map<String, dynamic>> companyDispatched = [];
  List<Map<String, dynamic>> personalTopItems = [];
  List<Map<String, dynamic>> personalLogs = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _userId = userProvider.id;
      _initUserInfo();
    });
  }

  Future<void> _initUserInfo() async {
    if (_userId == null) return;

    try {
      final res = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/user_info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': _userId}),
      );

      if (res.statusCode != 200) throw Exception('API请求失败: ${res.statusCode}');

      final data = jsonDecode(res.body)['data'];
      setState(() {
        _roleId = data['role_id'];
        selectedDepartment = data['department'];
        selectedTeam = data['team'];
        selectedEmployee = data['username'];
      });

      await _loadDropdowns();
      await _loadMindMapData();
    } catch (e) {
      print('初始化用户信息错误: $e');
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _loadDropdowns() async {
    if (_roleId == null) return;

    List<String> newDepartments = [];
    List<String> newTeams = [];
    List<String> newEmployees = [];

    try {
      // 部门
      if (_roleId! <= 2) {
        final res = await http.post(
          Uri.parse('http://10.0.2.2:5000/api/select_department'),
          headers: {'Content-Type': 'application/json'},
        );
        final deptData = jsonDecode(res.body)['data'] as List;
        newDepartments = deptData.map((e) => e['dept_name'] as String).toList();
      } else if (_roleId! >= 3 && selectedDepartment != null) {
        newDepartments = [selectedDepartment!];
      }

      // 团队
      if (_roleId! <= 2 || _roleId! == 3) {
        if (selectedDepartment != null) {
          final res = await http.post(
            Uri.parse('http://10.0.2.2:5000/api/select_team'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'department': selectedDepartment}),
          );
          final teamData = jsonDecode(res.body)['data'] as List;
          newTeams = teamData.map((e) => e['team_name'] as String).toList();
        }
      } else if (_roleId! >= 4 && selectedTeam != null) {
        newTeams = [selectedTeam!];
      }

      // 员工
      if (_roleId! <= 4 && selectedTeam != null) {
        final res = await http.post(
          Uri.parse('http://10.0.2.2:5000/api/select_user'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'team': selectedTeam}),
        );
        final userData = jsonDecode(res.body)['data'] as List;
        newEmployees = userData.map((e) => e['username'] as String).toList();
      } else if (_roleId! == 5) {
        newEmployees = [selectedEmployee ?? ''];
      }
    } catch (e) {
      print('加载下拉列表错误: $e');
    }

    setState(() {
      departments = newDepartments;
      teams = newTeams;
      employees = newEmployees;
    });
  }

  Future<void> _loadMindMapData() async {
    try {
      // 公司十大事项
      final resMatters = await http.get(Uri.parse('http://10.0.2.2:5000/api/company_top_matters'));
      if (resMatters.statusCode == 200) {
        final body = jsonDecode(resMatters.body);
        if (body['code'] == 0) {
          final list = (body['data'] as List).cast<Map>();
          companyMatters = list.map((e) => (e['title'] ?? '').toString()).toList();
        }
      }

      // 公司十大派发任务
      final resDispatched = await http.get(Uri.parse('http://10.0.2.2:5000/api/company_dispatched_tasks'));
      if (resDispatched.statusCode == 200) {
        final body = jsonDecode(resDispatched.body);
        if (body['code'] == 0) {
          companyDispatched = (body['data'] as List).cast<Map<String, dynamic>>();
        }
      }

      // 个人十大展示项
      if (_userId != null) {
        final resPersonal = await http.post(
          Uri.parse('http://10.0.2.2:5000/api/personal_top_items'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': _userId}),
        );
        if (resPersonal.statusCode == 200) {
          final body = jsonDecode(resPersonal.body);
          if (body['code'] == 0) {
            personalTopItems = (body['data'] as List).cast<Map<String, dynamic>>();
          }
        }

        // 个人日志
        final resLogs = await http.post(
          Uri.parse('http://10.0.2.2:5000/api/personal_logs'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': _userId}),
        );
        if (resLogs.statusCode == 200) {
          final body = jsonDecode(resLogs.body);
          if (body['code'] == 0) {
            personalLogs = (body['data'] as List).cast<Map<String, dynamic>>();
          }
        }
      }
    } catch (e) {
      print('加载导图数据错误: $e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  // 权限判断
  bool get canSelectDepartment => _roleId != null && _roleId! <= 2;
  bool get canSelectTeam => _roleId != null && (_roleId! <= 3 || _roleId! == 4);
  bool get canSelectEmployee => _roleId != null && _roleId! <= 4;

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool enabled,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true, // 防止 overflow
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC4DDFF)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
      style: const TextStyle(color: Colors.black87, fontSize: 14),
      items: items.isNotEmpty
          ? items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList()
          : [],
      onChanged: enabled && items.isNotEmpty ? onChanged : null,
    );
  }

  Widget _card({required Widget child, EdgeInsets? margin}) {
    return Container(
      margin: margin ?? const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        // 顶部下拉框
        Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFA5D8FF), Color(0xFF87CEEB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(bottom: BorderSide(color: Color(0xFFD1E8FF), width: 2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: '部门',
                  value: selectedDepartment,
                  items: departments,
                  onChanged: (v) => setState(() {
                    selectedDepartment = v;
                    selectedTeam = null;
                    selectedEmployee = null;
                    _loadDropdowns();
                  }),
                  enabled: canSelectDepartment,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdown(
                  label: '团队',
                  value: selectedTeam,
                  items: teams,
                  onChanged: (v) => setState(() {
                    selectedTeam = v;
                    selectedEmployee = null;
                    _loadDropdowns();
                  }),
                  enabled: canSelectTeam,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdown(
                  label: '员工',
                  value: selectedEmployee,
                  items: employees,
                  onChanged: (v) => setState(() => selectedEmployee = v),
                  enabled: canSelectEmployee,
                ),
              ),
            ],
          ),
        ),
        // 页面卡片布局：四等分
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - 12) / 2;
                final cardHeight = (constraints.maxHeight - 12) / 2;
                return Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '公司十大事项',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E3A8A)),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Scrollbar(
                                    child: ListView.separated(
                                      itemCount: companyMatters.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final title = companyMatters[index];
                                        // 用不同颜色做区分
                                        final color = index % 3 == 0
                                            ? Colors.redAccent
                                            : index % 3 == 1
                                                ? Colors.orange
                                                : Colors.green;
                                        final bg = index % 3 == 0
                                            ? Colors.red.shade50
                                            : index % 3 == 1
                                                ? Colors.yellow.shade50
                                                : Colors.green.shade50;
                                        return _priorityRow(title, color, bg);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '公司十大派发任务',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEC6A1E)),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Scrollbar(
                                    child: ListView.separated(
                                      itemCount: companyDispatched.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final item = companyDispatched[index];
                                        final status = (item['status'] ?? '').toString();
                                        final isDone = status.contains('done') || status == 'completed' || status == '已完成';
                                        final bg = isDone ? Colors.green.shade100 : Colors.orange.shade100;
                                        final color = isDone ? Colors.green : Colors.orange;
                                        return _taskRow(item['title'] ?? '', status, bg, color);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '个人十大展示项',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6D28D9)),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Scrollbar(
                                    child: ListView.separated(
                                      itemCount: personalTopItems.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final item = personalTopItems[index];
                                        final title = (item['title'] ?? '').toString();
                                        final end = (item['end_time'] ?? '').toString();
                                        final status = (item['status'] ?? '').toString();
                                        final icon = status == 'completed' || status == 'done' ? Icons.check_circle : Icons.circle_outlined;
                                        final color = status == 'completed' || status == 'done' ? Colors.green : Colors.blue;
                                        return _SimpleRow(icon: icon, color: color, title: title, time: end);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '个人日志',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEC4899)),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Scrollbar(
                                    child: ListView.separated(
                                      itemCount: personalLogs.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final log = personalLogs[index];
                                        return _logItem(
                                          (log['username'] ?? '').toString(),
                                          (log['content'] ?? '').toString(),
                                          (log['date'] ?? '').toString(),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _priorityRow(String title, Color dot, Color bg) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: bg,
              border: Border.all(color: bg),
            ),
            child: Text(title, style: const TextStyle(fontSize: 13)),
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.circle, color: dot, size: 18),
      ],
    );
  }

  Widget _taskRow(String title, String state, Color bg, Color textColor) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.person, size: 16, color: Colors.grey),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 13))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Text(state, style: TextStyle(color: textColor, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _logItem(String name, String content, String time) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.person, size: 16, color: Colors.grey),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(content, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 6),
              Text(time, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
            ]),
          ),
        ),
      ],
    );
  }
}

class _SimpleRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String time;
  const _SimpleRow({required this.icon, required this.color, required this.title, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(title)),
        if (time.isNotEmpty) Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
