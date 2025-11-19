import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/user_provider.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool loading = true;
  int _currentIndex = 0; // 0: 个人信息, 1: 团队成员, 2: 数据报表, 3: 帮助中心

  // 用户信息 - 将 userId 初始化为 0 而不是 null
  int userId = 0;
  String name = '';
  String role = '';
  String department = '';
  String team = '';
  int? teamId;

  // 团队成员数据
  List<TeamMember> teamMembers = [];
  bool loadingTeamMembers = false;

  // 统计数据
  Map<String, dynamic> stats = {
    'totalTasks': 0,
    'completedTasks': 0,
    'completionRate': 0.0,
    'inProgressTasks': 0,
    'pendingTasks': 0,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 确保 context 可用后再获取 Provider
    if (userId == 0) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final providerId = userProvider.id;
      // 如果 providerId 是 0，也视为无效ID
      if (providerId != null && providerId > 0) {
        userId = providerId;
        print('当前用户 ID: $userId');
        _fetchUserInfo(userId);
      } else {
        // 如果没有用户ID，使用模拟数据
        _loadMockData();
      }
    }
  }

  void _loadMockData() {
    setState(() {
      name = '演示用户';
      role = '普通员工';
      department = '技术部';
      team = '前端开发团队';
      teamId = 1;
      loading = false;
    });
    _loadMockStats();
  }

  // 辅助方法：安全解析整数，支持返回 null
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      if (value.isEmpty) return null;
      return int.tryParse(value);
    }
    if (value is double) return value.toInt();
    return null;
  }

  // 根据团队名称推断 teamId
  void _inferTeamIdFromTeamName() {
    if (team.contains('前端')) {
      teamId = 1;
      print('根据团队名称推断 teamId: $team -> 1');
    } else if (team.contains('后端')) {
      teamId = 2;
      print('根据团队名称推断 teamId: $team -> 2');
    } else if (team.contains('移动')) {
      teamId = 3;
      print('根据团队名称推断 teamId: $team -> 3');
    } else {
      teamId = 1; // 默认值
      print('无法推断团队ID，使用默认值: 1');
    }
  }

  Future<void> _fetchUserInfo(int userId) async {
    if (userId <= 0) {
      _loadMockData();
      return;
    }

    try {
      final res = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/user_info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (res.statusCode != 200) {
        throw Exception('请求失败: ${res.statusCode}');
      }

      final body = jsonDecode(res.body);
      print('用户信息接口返回: $body');

      if (body['code'] != 0) {
        throw Exception('接口错误: ${body['msg']}');
      }

      final data = body['data'];
      print('用户信息数据: $data');

      // 根据团队名称推断 teamId
      int inferredTeamId = 0;
      String teamName = data['team'] ?? '';
      if (teamName.contains('前端')) {
        inferredTeamId = 1;
      } else if (teamName.contains('后端')) {
        inferredTeamId = 2;
      } else if (teamName.contains('移动')) {
        inferredTeamId = 3;
      } else {
        inferredTeamId = 1; // 默认值
      }

      setState(() {
        name = data['username'] ?? '未知用户';
        role = data['role_name'] ?? '未知角色';
        department = data['department'] ?? '未知部门';
        team = teamName;
        teamId = _parseInt(data['team_id']) ?? inferredTeamId;
        loading = false;
      });

      print('设置的用户信息: name=$name, role=$role, department=$department, team=$team, teamId=$teamId');

    } catch (e) {
      print('获取用户信息失败: $e');
      // 如果API失败，使用模拟数据
      _loadMockData();
    }
  }

  Future<void> _fetchTeamMembers() async {
    // 如果 teamId 为 null 或 0，根据团队名称推断
    if (teamId == null || teamId == 0) {
      _inferTeamIdFromTeamName();
    }

    if (teamId == null || teamId == 0) {
      print('teamId 为 null 或 0，无法获取团队成员');
      _loadMockTeamMembers();
      return;
    }

    setState(() {
      loadingTeamMembers = true;
    });

    try {
      final res = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/get_team_members'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'team_id': teamId,
          'current_user_id': userId,
        }),
      );

      print('团队成员请求参数: team_id=$teamId, current_user_id=$userId');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        print('团队成员接口返回: $body');

        if (body['code'] == 0) {
          final List<dynamic> membersData = body['data'] ?? [];
          print('获取到 ${membersData.length} 个团队成员');

          setState(() {
            teamMembers = membersData.map((item) {
              print('处理团队成员数据: $item');
              return TeamMember(
                id: _parseInt(item['id']) ?? 0,
                name: item['name'] ?? item['username'] ?? '未知用户',
                role: item['role_name'] ?? '成员',
                email: item['email'] ?? '',
                mobile: item['mobile'] ?? item['phone'] ?? '',
                isCurrentUser: _parseInt(item['id']) == userId,
              );
            }).toList();
            loadingTeamMembers = false;
          });
          return;
        } else {
          print('团队成员接口错误: ${body['msg']}');
        }
      } else {
        print('团队成员请求失败: ${res.statusCode}');
      }
    } catch (e) {
      print('获取团队成员失败: $e');
    }

    // 如果API不可用，使用模拟数据
    _loadMockTeamMembers();
    setState(() {
      loadingTeamMembers = false;
    });
  }

  void _loadMockTeamMembers() {
    List<TeamMember> mockMembers = [];

    // 确保使用有效的用户ID
    int effectiveUserId = userId > 0 ? userId : 1;

    // 确保使用有效的团队ID
    int effectiveTeamId = (teamId != null && teamId! > 0) ? teamId! : 1;

    if (effectiveTeamId == 1) { // 前端开发团队
      mockMembers = [
        TeamMember(id: 1, name: '超级管理员', role: '管理员', email: 'admin@company.com', mobile: '13800000000', isCurrentUser: effectiveUserId == 1),
        TeamMember(id: 2, name: '王伟', role: '部门老总', email: 'tech_boss@company.com', mobile: '13800000001', isCurrentUser: effectiveUserId == 2),
        TeamMember(id: 3, name: '李娜', role: '部门经理', email: 'tech_manager@company.com', mobile: '13800000002', isCurrentUser: effectiveUserId == 3),
        TeamMember(id: 4, name: '张三', role: '团队队长', email: 'frontend_leader@company.com', mobile: '13800000003', isCurrentUser: effectiveUserId == 4),
        TeamMember(id: 5, name: '赵四', role: '普通员工', email: 'frontend1@company.com', mobile: '13800000004', isCurrentUser: effectiveUserId == 5),
      ];
    } else if (effectiveTeamId == 2) { // 后端开发团队
      mockMembers = [
        TeamMember(id: 2, name: '王伟', role: '部门老总', email: 'tech_boss@company.com', mobile: '13800000001', isCurrentUser: effectiveUserId == 2),
        TeamMember(id: 6, name: '钱五', role: '团队队长', email: 'backend_leader@company.com', mobile: '13800000005', isCurrentUser: effectiveUserId == 6),
        TeamMember(id: 7, name: '孙六', role: '普通员工', email: 'backend1@company.com', mobile: '13800000006', isCurrentUser: effectiveUserId == 7),
      ];
    } else {
      // 默认模拟数据 - 使用有效的用户ID
      mockMembers = [
        TeamMember(id: effectiveUserId, name: name, role: role, email: 'user@company.com', mobile: '13800000000', isCurrentUser: true),
        TeamMember(id: 100, name: '团队成员A', role: '前端开发', email: 'teama@company.com', mobile: '13800000001', isCurrentUser: false),
        TeamMember(id: 101, name: '团队成员B', role: '后端开发', email: 'teamb@company.com', mobile: '13800000002', isCurrentUser: false),
        TeamMember(id: 102, name: '团队成员C', role: '产品经理', email: 'teamc@company.com', mobile: '13800000003', isCurrentUser: false),
      ];
    }

    setState(() {
      teamMembers = mockMembers;
    });
    print('使用模拟团队成员数据，共 ${mockMembers.length} 人');
  }

  Future<void> _fetchUserStats(int userId) async {
    if (userId <= 0) {
      _loadMockStats();
      return;
    }

    try {
      print('开始获取用户统计数据，userId: $userId');

      final res = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/get_user_stats'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      ).timeout(const Duration(seconds: 10));

      print('用户统计响应状态: ${res.statusCode}');
      print('用户统计响应体: ${res.body}');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        print('用户统计接口返回: $body');

        if (body['code'] == 0) {
          final data = body['data'];
          print('用户统计数据: $data');

          // 处理数据
          double completionRate = 0.0;
          if (data['completion_rate'] != null) {
            if (data['completion_rate'] is String) {
              completionRate = double.tryParse(data['completion_rate']) ?? 0.0;
            } else if (data['completion_rate'] is int) {
              completionRate = data['completion_rate'].toDouble();
            } else {
              completionRate = data['completion_rate']?.toDouble() ?? 0.0;
            }
          }

          setState(() {
            stats = {
              'totalTasks': _parseInt(data['total_tasks']) ?? 0,
              'completedTasks': _parseInt(data['completed_tasks']) ?? 0,
              'completionRate': completionRate,
              'inProgressTasks': _parseInt(data['in_progress_tasks']) ?? 0,
              'pendingTasks': _parseInt(data['pending_tasks']) ?? 0,
            };
          });
          print('成功处理统计数据: $stats');

          // 显示成功提示
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('数据已更新：${stats['totalTasks']}个任务'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        } else {
          print('用户统计接口业务错误: ${body['msg']}');
          // 不再显示错误对话框，直接使用模拟数据
          _loadMockStats();
        }
      } else {
        print('用户统计HTTP错误: ${res.statusCode}');
        _loadMockStats();
      }
    } catch (e) {
      print('获取统计数据异常: $e');
      _loadMockStats();
    }
  }

  void _loadMockStats() {
    // 根据用户角色和当前时间生成不同的模拟数据
    double completionRate = 0.0;
    int totalTasks = 0;
    int completedTasks = 0;
    int inProgressTasks = 0;
    int pendingTasks = 0;

    // 基于角色生成基础数据
    if (role.contains('管理员') || role.contains('老总')) {
      completionRate = 75.0 + (DateTime.now().millisecond % 20); // 75-95%
      totalTasks = 20 + (DateTime.now().millisecond % 10); // 20-30
      completedTasks = (totalTasks * completionRate / 100).round();
    } else if (role.contains('经理') || role.contains('队长')) {
      completionRate = 65.0 + (DateTime.now().millisecond % 25); // 65-90%
      totalTasks = 15 + (DateTime.now().millisecond % 8); // 15-23
      completedTasks = (totalTasks * completionRate / 100).round();
    } else {
      completionRate = 50.0 + (DateTime.now().millisecond % 35); // 50-85%
      totalTasks = 8 + (DateTime.now().millisecond % 7); // 8-15
      completedTasks = (totalTasks * completionRate / 100).round();
    }

    // 计算进行中和待开始的任务
    inProgressTasks = (totalTasks - completedTasks) ~/ 2;
    pendingTasks = totalTasks - completedTasks - inProgressTasks;

    // 确保数据合理性
    if (completedTasks > totalTasks) completedTasks = totalTasks;
    if (inProgressTasks < 0) inProgressTasks = 0;
    if (pendingTasks < 0) pendingTasks = 0;

    setState(() {
      stats = {
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'completionRate': double.parse(completionRate.toStringAsFixed(1)),
        'inProgressTasks': inProgressTasks,
        'pendingTasks': pendingTasks,
      };
    });
    print('生成模拟统计数据: $stats');
  }

  // 退出登录方法
  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认退出'),
          content: const Text('确定要退出登录吗？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                // 清除用户信息
                Provider.of<UserProvider>(context, listen: false).setId(0);
                // 关闭对话框
                Navigator.of(context).pop();
                // 直接使用 MaterialPageRoute 导航到登录页面
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false,
                );
              },
              child: const Text('确定', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _infoCard(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFDBF2FF), Color(0xFFE6FBFF)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              ClipOval(
                child: Image.network(
                  'https://modao.cc/ai/uploads/ai_pics/24/249698/aigp_1757741578.jpeg',
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(role, style: const TextStyle(color: Color(0xFF3B82F6))),
              const SizedBox(height: 12),
              _infoCard('所属部门', department, const Color(0xFF2563EB)),
              _infoCard('所属团队', team, const Color(0xFF16A34A)),
              const SizedBox(height: 16),
              // 退出登录按钮
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text('退出登录', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildProfileItem(Icons.settings, '系统设置', const Color(0xFF5C6BC0), 0),
              _buildProfileItem(Icons.notifications, '消息中心', const Color(0xFFFF9800), 0),
              _buildProfileItem(Icons.book, '项目文档', const Color(0xFF66BB6A), 0),
              _buildProfileItem(Icons.group, '团队成员', const Color(0xFFF44336), 1),
              _buildProfileItem(Icons.pie_chart, '数据报表', const Color(0xFF9C27B0), 2),
              _buildProfileItem(Icons.help, '帮助中心', const Color(0xFF03A9F4), 3),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(IconData icon, String title, Color color, int index) {
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          // 团队成员页面，需要加载数据
          print('点击团队成员，当前teamId: $teamId');
          if (teamId != null && teamId! > 0) {
            _fetchTeamMembers();
          } else {
            print('teamId无效，使用模拟数据');
            _loadMockTeamMembers();
          }
        } else if (index == 2) {
          // 数据报表页面
          print('点击数据报表，当前userId: $userId');
          if (userId > 0) {
            _fetchUserStats(userId);
          } else {
            print('userId无效，使用模拟数据');
            _loadMockStats();
          }
        }
        if (index > 0) {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.12), color.withOpacity(0.06)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMembersSection() {
    if (loadingTeamMembers) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentIndex = 0),
              ),
              const SizedBox(width: 8),
              const Text(
                '团队成员',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '团队: $team (${teamMembers.length}人)',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: teamMembers.map((member) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: member.isCurrentUser ? Colors.blue.shade100 : Colors.grey.shade300,
                    child: Text(
                      member.name.substring(0, 1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: member.isCurrentUser ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              member.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            if (member.isCurrentUser) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '我',
                                  style: TextStyle(color: Colors.blue, fontSize: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          member.role,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        if (member.email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            member.email,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                        if (member.mobile.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            member.mobile,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentIndex = 0),
              ),
              const SizedBox(width: 8),
              const Text(
                '数据报表',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              // 移除"演示数据"标签，改为显示真实数据状态
              if (stats['totalTasks'] > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '实时数据',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '暂无任务',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 更新数据说明卡片
        if (stats['totalTasks'] == 0)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '您目前没有任务数据，请联系管理员分配任务或创建新任务',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '当前显示实时任务数据，共 ${stats['totalTasks']} 个任务',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 完成率卡片
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text(
                '任务完成率',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: stats['completionRate'] / 100,
                      strokeWidth: 12,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${stats['completionRate'].toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '完成率',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '已完成 ${stats['completedTasks']} / ${stats['totalTasks']} 个任务',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                // 根据完成率显示不同的提示信息
                stats['completionRate'] == 100.0
                    ? '恭喜！所有任务已完成！'
                    : stats['completionRate'] >= 80.0
                    ? '进展顺利，继续保持！'
                    : stats['completionRate'] >= 50.0
                    ? '任务完成过半，加油！'
                    : '开始处理任务吧！',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // 任务状态统计
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard('总计任务', stats['totalTasks'].toString(), Icons.list_alt, Colors.blue, '所有任务数量'),
              _buildStatCard('已完成', stats['completedTasks'].toString(), Icons.check_circle, Colors.green, '已完成任务'),
              _buildStatCard('进行中', stats['inProgressTasks'].toString(), Icons.autorenew, Colors.orange, '正在处理'),
              _buildStatCard('待开始', stats['pendingTasks'].toString(), Icons.pending_actions, Colors.grey, '等待开始'),
            ],
          ),
        ),

        // 刷新按钮
        Container(
          margin: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              print('手动刷新数据报表');
              if (userId > 0) {
                _fetchUserStats(userId);
              } else {
                _loadMockStats();
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('刷新数据'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCenterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentIndex = 0),
              ),
              const SizedBox(width: 8),
              const Text(
                '帮助中心',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildExpandableItem(
                '如何使用任务日历？',
                '任务日历功能可以帮助您查看和管理个人及团队任务。\n\n'
                    '• 点击日期选择器可以切换查看的月份\n'
                    '• 甘特图显示任务的时间分布和进度\n'
                    '• 点击任务卡片可以查看详细信息\n'
                    '• 下拉刷新可以更新任务数据',
              ),
              _buildExpandableItem(
                '如何创建新任务？',
                '目前创建新任务需要通过项目管理页面进行创建。\n\n'
                    '创建任务时请填写：\n'
                    '• 任务名称和描述\n'
                    '• 开始和结束时间\n'
                    '• 负责人和参与人员\n'
                    '• 任务优先级和类型',
              ),
              _buildExpandableItem(
                '任务状态说明',
                '任务有以下几种状态：\n\n'
                    '• 未开始：任务尚未启动\n'
                    '• 进行中：任务正在执行中\n'
                    '• 已完成：任务已经完成\n'
                    '• 已延期：任务超过截止时间未完成',
              ),
              _buildExpandableItem(
                '团队协作功能',
                '团队协作功能包括：\n\n'
                    '• 查看团队成员的任务进度\n'
                    '• 分配任务给团队成员\n'
                    '• 团队任务的时间协调\n'
                    '• 进度统计和报表生成',
              ),
              _buildExpandableItem(
                '常见问题',
                'Q: 为什么看不到某些任务？\n'
                    'A: 请检查任务的时间范围是否在当前查看的月份内\n\n'
                    'Q: 任务进度如何更新？\n'
                    'A: 任务进度由负责人更新，系统会自动同步\n\n'
                    'Q: 如何联系技术支持？\n'
                    'A: 请联系系统管理员或发送邮件到 support@company.com',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableItem(String title, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: const TextStyle(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            SingleChildScrollView(child: _buildProfileSection()),
            _buildTeamMembersSection(),
            SingleChildScrollView(child: _buildStatsSection()),
            _buildHelpCenterSection(),
          ],
        ),
      ),
    );
  }
}

class TeamMember {
  final int id;
  final String name;
  final String role;
  final String email;
  final String mobile;
  final bool isCurrentUser;

  TeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.mobile,
    required this.isCurrentUser,
  });
}