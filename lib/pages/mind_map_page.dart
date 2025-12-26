import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api.dart';
import 'mind_map_detail.dart';

class MindMapPage extends StatefulWidget {
  const MindMapPage({super.key});

  @override
  State<MindMapPage> createState() => _MindMapPageState();
}

class _MindMapPageState extends State<MindMapPage> {
  int? _userId;
  int? _roleId;
  int? _targetUserId;
  String? selectedDepartment;
  String? selectedTeam;
  String? selectedEmployee;

  List<String> departments = [];
  List<String> teams = [];
  List<String> employees = [];

  // 数据源
  // 不要转成 List<String>
  List<Map<String, dynamic>> companyMatters = [];
  List<Map<String, dynamic>> companyDispatched = [];
  List<Map<String, dynamic>> personalTopItems = [];
  List<Map<String, dynamic>> personalLogs = [];

  // 选中用于展示的数据
  List<Map<String, dynamic>> selectedCompanyMatters = [];
  List<Map<String, dynamic>> selectedCompanyDispatched = [];
  List<Map<String, dynamic>> selectedPersonalTopItems = [];
  List<Map<String, dynamic>> selectedPersonalLogs = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _userId = userProvider.id;
      _targetUserId = _userId;
      _initUserInfo();
    });
  }

  Future<void> _initUserInfo() async {
    if (_userId == null) return;

    try {
      final apiUrl = UserProvider.getApiUrl('user_info');
      final res = await http.post(
        Uri.parse(apiUrl),
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
        final apiUrl = UserProvider.getApiUrl('select_department');
        final res = await http.post(
          Uri.parse(apiUrl),
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
          final apiUrl = UserProvider.getApiUrl('select_team');
          final res = await http.post(
            Uri.parse(apiUrl),
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
        final apiUrl = UserProvider.getApiUrl('select_user');
        final res = await http.post(
          Uri.parse(apiUrl),
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
      // 每次加载前，清空已选择数据，确保根据最新数据刷新展示
      selectedCompanyMatters = [];
      selectedCompanyDispatched = [];
      selectedPersonalTopItems = [];
      selectedPersonalLogs = [];

      // 公司十大事项
      var apiUrl = UserProvider.getApiUrl('company_top_matters');
      final resMatters = await http.get(Uri.parse(apiUrl));
      if (resMatters.statusCode == 200) {
        final body = jsonDecode(resMatters.body);
        if (body['code'] == 0) {
          final list = (body['data'] as List).cast<Map<String, dynamic>>();
          companyMatters = list;
        }
        print('✅ companyMatters = $companyMatters');
      }

      // 公司十大派发任务
      apiUrl = UserProvider.getApiUrl('company_dispatched_tasks');
      final resDispatched = await http.get(Uri.parse(apiUrl));
      if (resDispatched.statusCode == 200) {
        final body = jsonDecode(resDispatched.body);
        if (body['code'] == 0) {
          companyDispatched = (body['data'] as List).cast<Map<String, dynamic>>();
        }
      }

      // 个人十大展示项
      apiUrl = UserProvider.getApiUrl('personal_top_items');
      if (_userId != null) {
        final resPersonal = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': _targetUserId}),
        );
        if (resPersonal.statusCode == 200) {
          final body = jsonDecode(resPersonal.body);
          if (body['code'] == 0) {
            personalTopItems = (body['data'] as List).cast<Map<String, dynamic>>();
          }
        }

        // 个人日志
        apiUrl = UserProvider.getApiUrl('personal_logs');
        final resLogs = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': _targetUserId}),
        );
        if (resLogs.statusCode == 200) {
          final body = jsonDecode(resLogs.body);
          if (body['code'] == 0) {
            personalLogs = (body['data'] as List).cast<Map<String, dynamic>>();
          }
        }
      }

      // 默认全部展示（用户还未重新勾选时）
      selectedCompanyMatters = List<Map<String, dynamic>>.from(companyMatters);
      selectedCompanyDispatched = List<Map<String, dynamic>>.from(companyDispatched);
      selectedPersonalTopItems = List<Map<String, dynamic>>.from(personalTopItems);
      selectedPersonalLogs = List<Map<String, dynamic>>.from(personalLogs);
    } catch (e) {
      print('加载导图数据错误: $e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }
  Future<void> _getUserIdByName(String username) async {
    try {
      final apiUrl = UserProvider.getApiUrl('get_user_id_by_name');
      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['code'] == 0) {
          final data = body['data'];
          setState(() {
            _targetUserId = data['id'];
            selectedEmployee = data['name'];
          });
          print('现在观察: $_targetUserId');
          await _loadMindMapData();
        } else {
          print('用户不存在: ${body['msg']}');
        }
      } else {
        print('接口请求失败: ${res.statusCode}');
      }
    } catch (e) {
      print('获取用户ID错误: $e');
    }
  }
  // 权限判断
  bool get canSelectDepartment => _roleId != null && _roleId! <= 2;
  bool get canSelectTeam => _roleId != null && (_roleId! <= 3 || _roleId! == 4);
  bool get canSelectEmployee => _roleId != null && _roleId! <= 4;
  bool get canEditCompanyBlocks => _roleId != null && _roleId! <= 2;

  // 通用弹窗选择器
  void _openSelectionDialog<T>({
    required String title,
    required List<T> sourceList,
    required List<T> currentSelected,
    required bool canConfirm,
    required void Function(List<T>) onConfirm,
    required String Function(T) displayText,
  }) {
    // 即使列表为空也允许弹出窗格（只是内容为空）
    final List<T> initial =
        currentSelected.isNotEmpty ? List<T>.from(currentSelected) : List<T>.from(sourceList);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              final selected = initial;
              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    // 标题 + 关闭
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // 内容列表
                    Expanded(
                      child: ListView.builder(
                        itemCount: sourceList.length,
                        itemBuilder: (context, index) {
                          final item = sourceList[index];
                          final text = displayText(item);
                          final bool isChecked = selected.contains(item);
                          return CheckboxListTile(
                            title: Text(
                              text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            value: isChecked,
                            onChanged: (v) {
                              setStateDialog(() {
                                if (v == true) {
                                  if (!selected.contains(item)) {
                                    selected.add(item);
                                  }
                                } else {
                                  selected.remove(item);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: canConfirm
                              ? () {
                                  onConfirm(List<T>.from(selected));
                                  Navigator.of(context).pop();
                                }
                              : null,
                          child: Text(canConfirm ? '确定' : '没有权限选择展示'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

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
          height: 100,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
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
                  onChanged: (v) {
                    setState(() {
                      selectedDepartment = v;
                      selectedTeam = null;
                      selectedEmployee = null;
                    });

                    _loadDropdowns();
                  },
                  enabled: canSelectDepartment,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdown(
                  label: '团队',
                  value: selectedTeam,
                  items: teams,
                  onChanged: (v) {
                    setState(() {
                      selectedTeam = v;
                      selectedEmployee = null;
                    });

                    _loadDropdowns();
                  },
                  enabled: canSelectTeam,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdown(
                  label: '员工',
                  value: selectedEmployee,
                  items: employees,
                  onChanged: (v) async {  // ✅ async
                    if (v != null) {
                      setState(() {
                        selectedEmployee = v;
                      });
                      await _getUserIdByName(v);  // 调接口获取用户 ID
                    }
                  },
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
                        // 公司十大事项
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MindMapDetailPage(
                                    api: UserProvider.getApiUrl('company_top_matters'),
                                    userId: _userId!,
                                    targetUserId: _targetUserId!,
                                  ),
                                ),
                              );
                              await _loadMindMapData();
                            },
                            child: _card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '公司十大事项',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Scrollbar(
                                      child: ListView.separated(
                                        padding: EdgeInsets.zero,
                                        itemCount: selectedCompanyMatters.isNotEmpty
                                            ? selectedCompanyMatters.length
                                            : companyMatters.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          final list = selectedCompanyMatters.isNotEmpty
                                              ? selectedCompanyMatters
                                              : companyMatters;
                                          final item = list[index];
                                          final avatarFullUrl = (item['avatar_url'] ?? '').isNotEmpty
                                              ? '${UserProvider.baseUrl}${item['avatar_url']}'
                                              : null;
                                          return _taskRow(item['title'] ?? '', avatarFullUrl, index);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 公司十大派发任务
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: GestureDetector(
                            onTap: () async{
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MindMapDetailPage(
                                    api: UserProvider.getApiUrl('company_dispatched_tasks'),
                                    userId: _userId!,
                                    targetUserId: _targetUserId!,
                                  ),
                                ),
                              );
                              await _loadMindMapData();
                            },
                            child: _card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '公司十大派发任务',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEC6A1E),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Scrollbar(
                                      child: ListView.separated(
                                        padding: EdgeInsets.zero,
                                        itemCount: selectedCompanyDispatched.isNotEmpty
                                            ? selectedCompanyDispatched.length
                                            : companyDispatched.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          final list = selectedCompanyDispatched.isNotEmpty
                                              ? selectedCompanyDispatched
                                              : companyDispatched;
                                          final item = list[index];
                                          final avatarFullUrl = (item['avatar_url'] ?? '').isNotEmpty
                                            ? '${UserProvider.baseUrl}${item['avatar_url']}'
                                            : null;
                                          return _taskRow(item['title'] ?? '', avatarFullUrl, index);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // 个人十大展示项
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: GestureDetector(
                            onTap: () async{
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MindMapDetailPage(
                                    api: UserProvider.getApiUrl('personal_top_items'),
                                    userId: _userId!,
                                    targetUserId: _targetUserId!,
                                  ),
                                ),
                              );
                              await _loadMindMapData();
                            },
                            child: _card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '个人十大展示项',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6D28D9),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Scrollbar(
                                      child: ListView.separated(
                                        padding: EdgeInsets.zero,
                                        itemCount: selectedPersonalTopItems.isNotEmpty
                                            ? selectedPersonalTopItems.length
                                            : personalTopItems.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          final list = selectedPersonalTopItems.isNotEmpty
                                              ? selectedPersonalTopItems
                                              : personalTopItems;
                                          final item = list[index];
                                          final title = (item['title'] ?? '').toString();
                                          final end = (item['end_time'] ?? '').toString();
                                          final status = (item['status'] ?? '').toString();
                                          final icon = status == 'completed' ||
                                                  status == 'done'
                                              ? Icons.check_circle
                                              : Icons.circle_outlined;
                                          final color = status == 'completed' ||
                                                  status == 'done'
                                              ? Colors.green
                                              : Colors.blue;
                                          return Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(icon, color: color, size: 16),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      title,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    if (end.isNotEmpty)
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 2),
                                                        child: Text(
                                                          end,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey.shade500,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 个人日志
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MindMapDetailPage(
                                    api: UserProvider.getApiUrl('personal_logs'),
                                    userId: _userId!,
                                    targetUserId: _targetUserId!,
                                  ),
                                ),
                              );
                              await _loadMindMapData();
                            },
                            child: _card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '个人日志',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEC4899),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Scrollbar(
                                      child: ListView.separated(
                                        padding: EdgeInsets.zero,
                                        itemCount: selectedPersonalLogs.isNotEmpty
                                            ? selectedPersonalLogs.length
                                            : personalLogs.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          final log = selectedPersonalLogs.isNotEmpty
                                              ? selectedPersonalLogs[index]
                                              : personalLogs[index];
                                          final content = (log['content'] ?? '').toString();
                                          final date = (log['log_date'] ?? '').toString(); // 或 create_time，看你想显示哪一个
                                          return _logItem(content, date);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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

  Widget _taskRow(String title, String? avatarUrl, int index) {
    // 颜色轮换背景参考公司十大事项
    Color bg = index % 3 == 0
        ? Colors.red.shade50
        : index % 3 == 1
            ? Colors.yellow.shade50
            : Colors.green.shade50;

    Color borderColor = bg; // 边框淡色，跟背景一致

    return Row(
      children: [
        // 头像
        CircleAvatar(
          radius: 14,
          backgroundColor: Colors.grey[300],
          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
              ? NetworkImage(avatarUrl)
              : null,
          child: (avatarUrl == null || avatarUrl.isEmpty)
              ? const Icon(Icons.person, size: 16, color: Colors.grey)
              : null,
        ),
        const SizedBox(width: 8),
        // 文字框
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor), // 边框淡色
            ),
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }

  Widget _logItem(String content, String date) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧状态圈，可统一颜色或使用蓝色
        Icon(Icons.circle_outlined, color: Colors.blue, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 内容
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              // 日期
              if (date.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    date,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
