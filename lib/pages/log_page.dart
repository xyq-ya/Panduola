import 'package:flutter/material.dart';

class LogPage extends StatelessWidget {
  const LogPage({super.key});

  // 通用的颜色变暗函数（模拟 shade700）
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
          _noteCard(
            "新增日历组件",
            "在主页中集成了自定义日历选择器。",
            "2025-10-03 11:23",
            Colors.teal,
            "开发",
          ),
          _noteCard(
            "会议记录",
            "讨论项目分支管理和版本控制。",
            "2025-10-02 14:00",
            Colors.blueAccent,
            "会议",
          ),
          _noteCard(
            "用户体验调研",
            "收集了8位用户对交互界面的反馈。",
            "2025-09-30 10:15",
            Colors.pinkAccent,
            "调研",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 可添加添加新日志逻辑
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