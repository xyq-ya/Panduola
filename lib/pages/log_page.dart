import 'package:flutter/material.dart';

/// 日志页面
class LogPage extends StatelessWidget {
  const LogPage({super.key});

  // 通用的颜色变暗函数
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          int currentUserId = 1;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTaskPage(
                creatorId: currentUserId,
                parentId: null,
              ),
            ),
          );
        },
        backgroundColor: Colors.purpleAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, size: 28, color: Colors.white),
      ),
    );
  }
}

/// 创建任务页面（卡通风格）
class AddTaskPage extends StatefulWidget {
  final int creatorId;
  final int? parentId;

  const AddTaskPage({super.key, required this.creatorId, this.parentId});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _assignedIdController = TextEditingController();
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(days: 1));
  String _assignedType = 'personal';
  String _status = '待执行';
  int _progress = 0;
  late int _creatorId;
  int? _parentId;

  @override
  void initState() {
    super.initState();
    _creatorId = widget.creatorId;
    _parentId = widget.parentId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assignedIdController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startTime : _endTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _startTime : _endTime),
      );
      if (time != null) {
        setState(() {
          final dateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
          if (isStart) {
            _startTime = dateTime;
          } else {
            _endTime = dateTime;
          }
        });
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      print("parent_id: $_parentId");
      print("title: ${_titleController.text}");
      print("description: ${_descriptionController.text}");
      print("creator_id: $_creatorId");
      print("assigned_type: $_assignedType");
      print("assigned_id: ${_assignedIdController.text}");
      print("start_time: $_startTime");
      print("end_time: $_endTime");
      print("status: $_status");
      print("progress: $_progress");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('任务已创建')),
      );

      Navigator.pop(context);
    }
  }

  // 卡通风格表单卡片
  Widget _buildCard({required Widget child, Color color = Colors.deepPurple}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建任务'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      backgroundColor: const Color(0xFFF6F5F8),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildCard(
                child: TextFormField(
                  initialValue: _parentId?.toString(),
                  decoration: const InputDecoration(
                    labelText: '父任务ID（可选）',
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _parentId = value.isEmpty ? null : int.tryParse(value);
                  },
                ),
              ),
              _buildCard(
                child: TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '任务标题',
                    border: InputBorder.none,
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? '请输入任务标题' : null,
                ),
              ),
              _buildCard(
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '任务详情',
                    border: InputBorder.none,
                  ),
                ),
              ),
              _buildCard(
                child: DropdownButtonFormField<String>(
                  value: _assignedType,
                  items: const [
                    DropdownMenuItem(value: 'company', child: Text('公司')),
                    DropdownMenuItem(value: 'department', child: Text('部门')),
                    DropdownMenuItem(value: 'team', child: Text('团队')),
                    DropdownMenuItem(value: 'personal', child: Text('个人')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _assignedType = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: '分发等级',
                    border: InputBorder.none,
                  ),
                ),
              ),
              _buildCard(
                child: TextFormField(
                  controller: _assignedIdController,
                  decoration: const InputDecoration(
                    labelText: '分发对象ID',
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value == null || value.isEmpty ? '请输入分发对象ID' : null,
                ),
              ),
              _buildCard(
                child: ListTile(
                  title: Text('开始时间: $_startTime'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _pickDateTime(context, true),
                ),
                color: Colors.teal,
              ),
              _buildCard(
                child: ListTile(
                  title: Text('结束时间: $_endTime'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _pickDateTime(context, false),
                ),
                color: Colors.orangeAccent,
              ),
              _buildCard(
                child: DropdownButtonFormField<String>(
                  value: _status,
                  items: const [
                    DropdownMenuItem(value: '待执行', child: Text('待执行')),
                    DropdownMenuItem(value: '进行中', child: Text('进行中')),
                    DropdownMenuItem(value: '已完成', child: Text('已完成')),
                    DropdownMenuItem(value: '已取消', child: Text('已取消')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _status = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: '任务状态',
                    border: InputBorder.none,
                  ),
                ),
              ),
              _buildCard(
                child: TextFormField(
                  initialValue: '0',
                  decoration: const InputDecoration(
                    labelText: '完成进度(0-100)',
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _progress = int.tryParse(value) ?? 0;
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '创建任务',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
