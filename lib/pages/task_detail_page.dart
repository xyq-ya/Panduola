import 'dart:convert';
import 'dart:io';
import 'dart:async'; 
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'home_page.dart';
import '../providers/user_provider.dart';

class TaskDetailPage extends StatefulWidget {
  final int taskId;
  const TaskDetailPage({super.key, required this.taskId});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  Map<String, dynamic>? _taskDetail;
  List<Map<String, dynamic>> _subTasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await _loadTaskDetail();
    await _loadSubTasks();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadTaskDetail() async {
    try {
      final apiUrl = UserProvider.getApiUrl('get_task_detail');
      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"task_id": widget.taskId}),
      );
      final data = jsonDecode(res.body);
      if (data['code'] == 0 && data['data'] != null) {
        _taskDetail = Map<String, dynamic>.from(data['data']);
      }
    } catch (e) {
      print("❌ 加载任务详情异常: $e");
    }
  }

  Future<void> _loadSubTasks() async {
    try {
      final apiUrl = UserProvider.getApiUrl('get_sub_tasks');
      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"task_id": widget.taskId}),
      );
      final data = jsonDecode(res.body);
      if (data['code'] == 0 && data['data'] != null) {
        _subTasks = List<Map<String, dynamic>>.from(data['data']);
      }
    } catch (e) {
      print("❌ 子任务加载失败: $e");
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _statusText(String? status) {
    switch (status) {
      case 'in_progress':
        return "进行中";
      case 'completed':
        return "已完成";
      default:
        return "待处理";
    }
  }

  Widget _actionButtons(Map<String, dynamic> task, int userId) {
    List<Widget> buttons = [];

    // 分发任务按钮条件
    if (_subTasks.isEmpty && task['assigned_type'] != 'personal' && userId == task['assigned_id']) {
      buttons.add(
        ElevatedButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DistributeTaskPage(
                  taskId: task['id'],
                  assignedType: task['assigned_type'],
                  assignedId: task['assigned_id'].toString(),
                  startTime: task['start_time'] ?? '',
                  endTime: task['end_time'] ?? '',
                ),
              ),
            );
            if (result == true) _loadSubTasks();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple.shade100,
            foregroundColor: Colors.deepPurple.shade800,
          ),
          child: const Text("分发任务"),
        ),
      );
    }

    // 汇报进度按钮条件
    if (task['assigned_type'] == 'personal' && userId == task['assigned_id']) {
      buttons.add(
        ElevatedButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WorkLogPage(taskId: task['id']),
              ),
            );
            if (result == true) _loadSubTasks();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade100,
            foregroundColor: Colors.green.shade800,
          ),
          child: const Text("汇报进度"),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink(); // 都不显示时返回空

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttons,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userId = userProvider.id ?? 0;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_taskDetail == null) {
      return const Scaffold(
        body: Center(child: Text("任务不存在或已删除")),
      );
    }

    final task = _taskDetail!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("任务详情"),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _buildTaskCard(task),
          const SizedBox(height: 18),
          _sectionTitle("任务描述"),
          _infoCardContent(task['description'] ?? "无描述"),
          const SizedBox(height: 18),
          _sectionTitle("基本信息"),
          _infoCard("创建人", task['creator_name'] ?? "未指定", Icons.person),
          _infoCard("负责人", task['assigned_name'] ?? "未指定", Icons.group),
          _infoCard("开始时间", task['start_time'] ?? "未知", Icons.access_time),
          _infoCard("结束时间", task['end_time'] ?? "未知", Icons.timer_off),
          const SizedBox(height: 18),
          _taskImageSection(task), // 单独的任务图片区域
          const SizedBox(height: 22),
          _sectionTitle("子任务"),
          if (_subTasks.isEmpty)
            const Text("暂无子任务", style: TextStyle(color: Colors.grey, fontSize: 14)),
          if (_subTasks.isNotEmpty)
            Column(children: _subTasks.map((sub) => _buildSubTaskCard(sub)).toList()),
          const SizedBox(height: 20),
          _actionButtons(task, userId),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ------------------ 构建单个任务卡片 ------------------
  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task['title'] ?? "未命名任务",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text("任务进度", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: ((task['progress'] ?? 0) as num) / 100,
            minHeight: 10,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          ),
          const SizedBox(height: 6),
          Text("${task['progress'] ?? 0}%",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text("开始: ${task['start_time'] ?? '未知'}"),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.timer_off, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text("结束: ${task['end_time'] ?? '未知'}"),
          ]),
        ],
      ),
    );
  }

  // ------------------ 单独的任务图片区域 ------------------
  Widget _taskImageSection(Map<String, dynamic> task) {
    final imageUrl = task['image_url'] != null && task['image_url'].isNotEmpty
        ? "${UserProvider.baseUrl}${task['image_url']}"
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("任务图片"),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                          child: Icon(Icons.broken_image, size: 40, color: Colors.grey));
                    },
                  )
                : const Center(
                    child: Text("暂无任务图片", style: TextStyle(color: Colors.grey))),
          ),
        ),
      ],
    );
  }

  // ------------------ 子任务卡片 ------------------
  Widget _buildSubTaskCard(Map<String, dynamic> sub) {
    final color = _statusColor(sub['status']);
    final statusText = _statusText(sub['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub['title'] ?? "未命名子任务",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: ((sub['progress'] ?? 0) as num) / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                ),
                const SizedBox(height: 4),
                Text("${sub['progress'] ?? 0}%", style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(sub['assigned_name'] ?? "未指定",
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(statusText,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ 通用方法 ------------------
  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _infoCard(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }

  Widget _infoCardContent(String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(content),
    );
  }

  BoxDecoration _cardDeco() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}

class DistributeTaskPage extends StatefulWidget {
  final int taskId;
  final String assignedType; // 父任务 assigned_type
  final String assignedId;   // 父任务 assigned_id
  final String startTime;    // 父任务开始时间
  final String endTime;      // 父任务结束时间

  const DistributeTaskPage({
    super.key,
    required this.taskId,
    required this.assignedType,
    required this.assignedId,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<DistributeTaskPage> createState() => _DistributeTaskPageState();
}

class _DistributeTaskPageState extends State<DistributeTaskPage> {
  final _formKey = GlobalKey<FormState>();

  // 任务块列表，每个块代表一条要分发的任务
  List<Map<String, dynamic>> _taskBlocks = [
    {
      'title': TextEditingController(),
      'desc': TextEditingController(),
      'target': null,
      'image': null, // 新增图片字段
    }
  ];

  List<Map<String, dynamic>> _targetList = [];
  bool _loadingTargets = false;

  @override
  void initState() {
    super.initState();
    _loadTargets();
  }

  // -------------------- 加载分发目标 --------------------
  Future<void> _loadTargets() async {
    setState(() => _loadingTargets = true);

    try {
      final url = Uri.parse(UserProvider.getApiUrl('get_task_targets'));
      final body = {
        'assigned_type': widget.assignedType,
        'assigned_id': widget.assignedId,
      };

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);
      if (data['code'] == 0 && data['data'] != null) {
        setState(() => _targetList = List<Map<String, dynamic>>.from(data['data']));
      } else {
        print("❌ 获取分发列表失败: ${data['msg']}");
      }
    } catch (e) {
      print("❌ 获取分发列表异常: $e");
    } finally {
      setState(() => _loadingTargets = false);
    }
  }

  // -------------------- 增加/删除任务块 --------------------
  void _addTaskBlock() {
    setState(() {
      _taskBlocks.add({
        'title': TextEditingController(),
        'desc': TextEditingController(),
        'target': null,
        'image': null,
      });
    });
  }

  void _removeTaskBlock() {
    if (_taskBlocks.isNotEmpty) {
      setState(() {
        _taskBlocks.removeLast();
      });
    }
  }

  // -------------------- 选择图片 --------------------
  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      setState(() {
        _taskBlocks[index]['image'] = File(result.path);
      });
    }
  }

  // -------------------- 上传图片 --------------------
  Future<String?> _uploadImage(File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(UserProvider.getApiUrl('upload_work_image')), // 后端接口
      );
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final data = jsonDecode(respStr);
      if (data['code'] == 0) return data['url'];
      return null;
    } catch (e) {
      print("❌ 图片上传异常: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("图片上传异常")),
      );
      return null;
    }
  }

  // -------------------- 提交任务 --------------------
  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final creatorId = userProvider.id;
    if (creatorId == null) return;

    List<Map<String, dynamic>> tasksToCreate = [];

    for (var block in _taskBlocks) {
      String? imageUrl;
      if (block['image'] != null) {
        imageUrl = await _uploadImage(block['image']);
      }

      final subAssignedType = widget.assignedType == 'dept'
          ? 'team'
          : (widget.assignedType == 'team' ? 'personal' : 'personal');

      tasksToCreate.add({
        "title": block['title'].text.trim(),
        "description": block['desc'].text.trim(),
        "creator_id": creatorId,
        "assigned_type": subAssignedType,
        "assigned_id": block['target'],
        "start_time": widget.startTime,
        "end_time": widget.endTime,
        "parent_id": widget.taskId,
        "image_url": imageUrl,
      });
    }

    try {
      bool allSuccess = true;
      for (var task in tasksToCreate) {
        final res = await http.post(
          Uri.parse(UserProvider.getApiUrl('create_sub_task')),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(task),
        );
        final data = jsonDecode(res.body);
        if (data['code'] != 0) {
          allSuccess = false;
          print("❌ 创建子任务失败: ${data['msg']}");
        }
      }

      if (allSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("子任务分发成功")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("部分子任务创建失败，请检查")),
        );
      }
    } catch (e) {
      print("❌ 创建子任务异常: $e");
    }
  }

  // -------------------- 卡片通用方法 --------------------
  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: child,
    );
  }

  // -------------------- 页面构建 --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("分发任务"), backgroundColor: Colors.deepPurple),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ..._taskBlocks.asMap().entries.map((entry) {
              int index = entry.key;
              var block = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("📦 分发对象 ${index + 1}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  // 任务标题
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
                  // 分发目标 Dropdown
                  _buildCard(
                    child: DropdownButtonFormField<String>(
                      value: block['target'],
                      hint: _loadingTargets
                          ? const Text("加载中...")
                          : Text(widget.assignedType == 'dept' ? "选择团队" : "选择用户"),
                      items: _targetList.map((item) {
                        final value = item['id'].toString();
                        final label = item['name'] ?? item['team_name'] ?? item['username'] ?? "";
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => block['target'] = v),
                      validator: (v) => v == null ? "请选择分发对象" : null,
                    ),
                  ),
                  // 任务描述
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
                  // 图片上传
                  _buildCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(block['image'] != null
                              ? block['image'].path.split("/").last
                              : "上传任务图片（可选）"),
                        ),
                        IconButton(
                          icon: const Icon(Icons.image),
                          onPressed: () => _pickImage(index),
                        ),
                      ],
                    ),
                  ),
                  const Divider(thickness: 1),
                ],
              );
            }).toList(),

            // 增加/删除分发对象按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _removeTaskBlock,
                  icon: const Icon(Icons.remove),
                  label: const Text("删除分发对象"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                ),
                ElevatedButton.icon(
                  onPressed: _addTaskBlock,
                  icon: const Icon(Icons.add),
                  label: const Text("增加分发对象"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("提交任务分发", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
class WorkLogPage extends StatefulWidget {
  final int taskId;

  const WorkLogPage({super.key, required this.taskId});

  @override
  State<WorkLogPage> createState() => _WorkLogPageState();
}

class _WorkLogPageState extends State<WorkLogPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _keywordsController = TextEditingController();
  final TextEditingController _progressController = TextEditingController();
  DateTime _logDate = DateTime.now();
  File? _pickedImage;
  bool _loading = false;

  double? _latitude;
  double? _longitude;
  String _locationMessage = "正在获取位置...";
  Location location = Location();  // 创建 Location 实例
  bool _serviceEnabled = false;
  PermissionStatus? _permissionGranted;
  @override
  @override
  void initState() {
    super.initState();
    // 改为延迟执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getLocation();
    });
  }

  Future<void> _getLocation() async {
    try {
      setState(() {
        _locationMessage = "正在获取位置...";
      });

      // 直接获取位置，设置超时
      LocationData locationData;
      
      try {
        // 使用 timeout() 方法，设置10秒超时
        locationData = await location.getLocation()
            .timeout(Duration(seconds: 10));
      } on TimeoutException {
        setState(() {
          _locationMessage = "获取位置超时（10秒）";
        });
        return;
      }

      // 检查位置数据是否有效
      if (locationData.latitude == null || locationData.longitude == null) {
        setState(() {
          _locationMessage = "位置数据为空";
        });
        return;
      }

      // 检查是否为有效坐标（排除0,0）
      if (locationData.latitude!.abs() < 0.0001 && 
          locationData.longitude!.abs() < 0.0001) {
        setState(() {
          _locationMessage = "获取到无效位置";
        });
        return;
      }

      setState(() {
        _latitude = locationData.latitude;
        _longitude = locationData.longitude;
        _locationMessage = "位置获取成功";
      });

    } on PlatformException catch (e) {
      // 处理平台异常
      print("平台异常: ${e.code} - ${e.message}");
      
      String errorMsg = "获取位置失败";
      if (e.code == 'PERMISSION_DENIED') {
        errorMsg = "定位权限被拒绝";
      } else if (e.code == 'SERVICE_DISABLED') {
        errorMsg = "定位服务未开启";
      }
      
      setState(() {
        _locationMessage = errorMsg;
      });
      
    } catch (e) {
      print("获取位置异常: $e");
      setState(() {
        _locationMessage = "获取位置失败";
      });
    }
  }
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    if (result != null) setState(() => _pickedImage = File(result.path));
  }

  Future<String?> _uploadImage(File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(UserProvider.getApiUrl('upload_work_log_image')),
      );
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final data = jsonDecode(respStr);
      if (data['code'] == 0) return data['url'];
      return null;
    } catch (e) {
      print("❌ 图片上传异常: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("图片上传异常")),
      );
      return null;
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.id;
    if (userId == null) return;

    String? imageUrl;
    if (_pickedImage != null) {
      imageUrl = await _uploadImage(_pickedImage!);
    }

    final body = {
      "task_id": widget.taskId,
      "user_id": userId,
      "content": _contentController.text.trim(),
      "keywords": _keywordsController.text.trim(),
      "image_url": imageUrl,
      "log_date": _logDate.toIso8601String().split("T")[0],
      "progress": int.tryParse(_progressController.text.trim()) ?? 0,
      "latitude": _latitude,
      "longitude": _longitude,
    };

    try {
      final res = await http.post(
        Uri.parse(UserProvider.getApiUrl('create_work_log')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = jsonDecode(res.body);
      if (data['code'] == 0) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("提交成功")));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("提交失败: ${data['msg']}")));
      }
    } catch (e) {
      print("❌ 提交异常: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("提交异常")));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _logDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _logDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("汇报进度"), backgroundColor: Colors.deepPurple),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 工作内容
            _buildCard(
              child: TextFormField(
                controller: _contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "工作内容",
                  border: InputBorder.none,
                ),
                validator: (v) => v == null || v.isEmpty ? "请输入工作内容" : null,
              ),
            ),
            const SizedBox(height: 12),
            // 关键词
            _buildCard(
              child: TextFormField(
                controller: _keywordsController,
                decoration: const InputDecoration(
                  labelText: "关键词（可选）",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 进度
            _buildCard(
              child: TextFormField(
                controller: _progressController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "完成进度（0-100）",
                  border: InputBorder.none,
                ),
                validator: (v) {
                  final num = int.tryParse(v ?? '');
                  if (num == null || num < 0 || num > 100) return "请输入 0-100 的数字";
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),
            // 日期选择
            _buildCard(
              child: ListTile(
                title: Text("日志日期: ${_logDate.toIso8601String().split("T")[0]}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 12),
            // 图片上传
            _buildCard(
              child: ListTile(
                title: Text(_pickedImage != null ? _pickedImage!.path.split("/").last : "上传图片（可选）"),
                trailing: const Icon(Icons.image),
                onTap: _pickImage,
              ),
            ),
            const SizedBox(height: 12),
            // 地理位置显示 & 刷新按钮
            _buildCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_latitude != null && _longitude != null)
                          Text(
                            "纬度: ${_latitude!.toStringAsFixed(6)}, 经度: ${_longitude!.toStringAsFixed(6)}",
                          )
                        else
                          Text(
                            _locationMessage, // 使用状态变量
                            style: TextStyle(
                              color: _locationMessage.contains("成功") 
                                  ? Colors.green 
                                  : _locationMessage.contains("超时") || 
                                    _locationMessage.contains("失败") || 
                                    _locationMessage.contains("拒绝") || 
                                    _locationMessage.contains("无效")
                                    ? Colors.orange
                                    : Colors.black,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.my_location, color: Colors.deepPurple),
                    onPressed: _getLocation,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("提交", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}
