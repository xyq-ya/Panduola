import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
// charts: use lightweight custom painters to avoid third-party SDK mismatch
import '../providers/user_provider.dart';
import '../services/ai_analysis.dart';

// === AI_ANALYSIS: KEYWORD EXTRACTION ===

// === AI_ANALYSIS: KEYWORD SCORING ===
// (moved AI analysis helpers to lib/services/ai_analysis.dart)

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  int? _userId; // 页面私有变量，保存用户 id
  Future<Map<String, dynamic>>? _aiFutureMap;
  // 如果后端返回了关键词/分数，保存在这里以驱动 UI 的动态展示
  Map<String, int>? _remoteKeywords;
  Map<String, double>? _remoteScores;
  String _aiProvider = 'local';

  void _refreshAi() {
    setState(() {
      _aiFutureMap = fetchAiAnalysisRaw(_sampleLogs).then((data) {
        // debug log: print provider and a short preview for easier troubleshooting
        try { print('fetchAiAnalysisRaw success, provider=${data['provider']}'); } catch (_) {}
        // 尝试从返回中读取 keywords 字段以驱动标签和词云
        final kws = <String, int>{};
        try {
          if (data.containsKey('keywords') && data['keywords'] is Map) {
            (data['keywords'] as Map).forEach((k, v) {
              kws[k.toString()] = int.tryParse(v.toString()) ?? 0;
            });
          }
        } catch (_) {}
        setState(() {
          _remoteKeywords = kws.isNotEmpty ? kws : null;
          _remoteScores = _remoteKeywords != null ? scoreKeywords(_remoteKeywords!) : null;
          _aiProvider = data['provider']?.toString() ?? 'remote';
        });
        return data;
      }).catchError((e) async {
        // debug log: record the error to console to help trace network/backend issues
        try { print('fetchAiAnalysisRaw failed: $e'); } catch (_) {}
        final localMap = extractKeywords(_sampleLogs);
        setState(() {
          _remoteKeywords = localMap;
          _remoteScores = scoreKeywords(localMap);
          _aiProvider = 'local';
        });
        final local = aiAnalysis(localMap);
        return {'analysis': local, 'provider': 'local', 'keywords': localMap};
      });
    });
  }

  // Chat UI state
  final TextEditingController _aiInputController = TextEditingController();
  final ScrollController _aiScrollController = ScrollController();
  List<Map<String, String>> _chatMessages = [];
  bool _aiSending = false;

  Future<void> _sendAiChat(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _chatMessages.add({'role': 'user', 'text': text});
      _aiSending = true;
      _aiInputController.clear();
    });
    try {
      final resp = await fetchAiAnalysisRaw(text).timeout(const Duration(seconds: 30));
      final assistant = resp['analysis']?.toString() ?? '（无回复）';
      setState(() {
        _chatMessages.add({'role': 'assistant', 'text': assistant});
      });
    } catch (e) {
      // fallback to local analysis
      final fallback = aiAnalysis(extractKeywords(text));
      setState(() {
        _chatMessages.add({'role': 'assistant', 'text': fallback});
      });
    } finally {
      setState(() {
        _aiSending = false;
      });
      // scroll to bottom
      await Future.delayed(const Duration(milliseconds: 100));
      if (_aiScrollController.hasClients) {
        _aiScrollController.animateTo(_aiScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    }
  }
  // === AI_ANALYSIS: SAMPLE LOGS ===
  // demo 日志文本（现实中应从后端拉取）
  final String _sampleLogs = '''
周一: 与产品讨论需求，会议 2 小时；完成接口文档编写；
周二: 代码实现模块 A，单元测试覆盖 80%；部署到测试环境；
周三: 调研第三方 SDK，处理线上异常；修复 bug；
周四: 团队同步会议，设计评审；文档整理；
周五: 优化性能，压测，准备下周计划；
''';

  @override
  void initState() {
    super.initState();
    // 页面初始化时获取一次 Provider 中的 id
    _userId = Provider.of<UserProvider>(context, listen: false).id;
    print('页面获取的用户 id：$_userId');
    // 使用统一的刷新方法发起初次 AI 请求，这样在 UI 上能清晰看到触发点并允许手动刷新
    _aiFutureMap = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAi());
  }

  Widget _statCard(String title, String subtitle, Color color, double percent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12), 
              borderRadius: BorderRadius.circular(12)
            ),
            child: Center(
              child: Text(
                '${(percent*100).toInt()}%', 
                style: TextStyle(color: color, fontWeight: FontWeight.bold)
              )
            )
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(color: Colors.grey))
              ]
            )
          ),
        ]
      ),
    );
  }

  Widget _buildWordCloud(Map<String, double> scores) {
    // === AI_ANALYSIS: WORD CLOUD ===
    // 按重要性调整字体大小
    final widgets = scores.entries.map((e) {
      final size = 12 + (e.value * 28);
      final color = Colors.primaries[e.key.hashCode % Colors.primaries.length];
      return GestureDetector(
        onTap: () => _showKeywordDetail(e.key),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Text(e.key, style: TextStyle(fontSize: size, color: color)),
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Wrap(children: widgets),
    );
    // === AI_ANALYSIS: WORD CLOUD END ===
  }

  void _showKeywordDetail(String word) {
    // === AI_ANALYSIS: KEYWORD DETAIL (delegated to service) ===
    final detail = keywordDetail(word, _sampleLogs);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('关键词：$word'),
        content: Text(detail),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
      ),
    );
  }

  Widget _buildPieChart() {
    final values = [40.0, 30.0, 20.0, 10.0];
    final labels = ['执行类', '沟通类', '规划类', '异常处理类'];
    final colors = [Colors.blue, Colors.orange, Colors.green, Colors.red];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        const Text('任务分类耗时占比', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: LayoutBuilder(builder: (ctx, constraints) {
            return GestureDetector(
              onTapUp: (details) {
                final local = details.localPosition;
                _handlePieTap(local, constraints.biggest, values, labels);
              },
              child: CustomPaint(
                painter: _PiePainter(values: values, colors: colors, labels: labels),
                child: Container(),
              ),
            );
          }),
        ),
      ]),
    );
  }

  Widget _buildBarChart() {
    final values = List.generate(7, (i) => ((i + 1) * 2).toDouble());
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('工作效率趋势（近7天）', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(children: [
              const Text('指标:'),
              const SizedBox(width: 8),
              DropdownButton<bool>(
                value: _barShowCount,
                items: const [
                  DropdownMenuItem(value: true, child: Text('完成任务数')),
                  DropdownMenuItem(value: false, child: Text('平均耗时')),
                ],
                onChanged: (v) => setState(() => _barShowCount = v ?? true),
              ),
              const SizedBox(width: 12),
              const Text('目标线:'),
              SizedBox(
                width: 60,
                child: TextFormField(
                  initialValue: _barTarget.toString(),
                  onFieldSubmitted: (s) {
                    final val = double.tryParse(s);
                    if (val != null) setState(() => _barTarget = val);
                  },
                ),
              )
            ])
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: CustomPaint(
            painter: _BarPainter(values: values, target: _barTarget),
            child: Container(),
          ),
        )
      ]),
    );
  }
  

  // AI analysis moved to lib/services/ai_analysis.dart (function: aiAnalysis)

  // 交互状态：柱状图模式与目标线
  bool _barShowCount = true; // true: 完成任务数, false: 平均耗时
  double _barTarget = 3.0;

  // 示例任务按分类映射（实际应来自后端）
  final Map<String, List<String>> _tasksByCategory = {
    '执行类': ['完成接口文档', '实现模块A', '性能优化'],
    '沟通类': ['需求讨论会议', '团队同步会议'],
    '规划类': ['编写周计划', '设计评审准备'],
    '异常处理类': ['修复线上 bug', '处理第三方异常']
  };

  void _showTasksForCategory(String category) {
    final list = _tasksByCategory[category] ?? [];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$category - 任务清单'),
        content: SizedBox(
          width: 400,
          child: ListView(
            shrinkWrap: true,
            children: list.map((t) => ListTile(title: Text(t))).toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
      ),
    );
  }

  void _handlePieTap(Offset localPos, Size size, List<double> values, List<String> labels) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final angle = (atan2(dy, dx) + 2 * pi) % (2 * pi);
    final total = values.fold(0.0, (a, b) => a + b);
    double accum = 0.0;
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * pi;
      if (angle >= accum && angle < accum + sweep) {
        _showTasksForCategory(labels[i]);
        return;
      }
      accum += sweep;
    }
  }

  @override
  Widget build(BuildContext context) {
  // 优先使用后端/远程返回的关键词与分数驱动标签和词云；若无则使用本地样例日志计算
  final tags = _remoteKeywords != null
    ? (_remoteKeywords!.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
      .take(8)
      .map((e) => e.key)
      .toList()
    : ['优化','会议','设计','开发','测试','部署','文档','迭代'];
  final freq = _remoteKeywords ?? extractKeywords(_sampleLogs);
  final scores = _remoteScores ?? scoreKeywords(freq);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(12), 
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((t) => Chip(
                  label: Text(t),
                  backgroundColor: Colors.blue.shade50
                )).toList()
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _statCard('任务进度分布', '已完成: 65% · 进行中: 20% · 未开始: 15%', Colors.green, 0.65)),
                const SizedBox(width: 12),
                Expanded(child: _statCard('优先级分布', '高:18 · 中:35 · 低:47', Colors.orange, 0.47)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(12), 
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === AI_ANALYSIS: UI START ===
                  const Text('AI建议助手', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50, 
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: const Icon(Icons.smart_toy, color: Color(0xFF8A3FFC))
                        ),
                        const SizedBox(height: 12),
                        Text('关键词云', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        _buildWordCloud(scores),
                        const SizedBox(height: 12),
                        _buildPieChart(),
                        const SizedBox(height: 12),
                        _buildBarChart(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('AI 智能分析', style: TextStyle(fontWeight: FontWeight.bold)),
                            Row(children: [
                              Text('来源: ', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              Text(_aiProvider, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _refreshAi,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('刷新 AI 建议', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                              )
                            ])
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Chat-style AI window: 如果 _chatMessages 为空，先用 FutureBuilder 拉取初始建议并塞入首条助手消息
                        Container(
                          height: 260,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              Expanded(
                                child: _chatMessages.isEmpty
                                    ? FutureBuilder<Map<String, dynamic>>(
                                        future: _aiFutureMap,
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Text('正在加载 AI 建议...', style: TextStyle(color: Colors.grey)));
                                          if (snapshot.hasError || snapshot.data == null) {
                                            final local = aiAnalysis(freq);
                                            return Padding(padding: const EdgeInsets.all(8.0), child: Text(local, style: const TextStyle(color: Colors.grey)));
                                          }
                                          final data = snapshot.data!;
                                          final text = data['analysis']?.toString() ?? aiAnalysis(freq);
                                          final provider = data['provider']?.toString() ?? 'remote';
                                          // 如果返回中包含 keywords，保存以驱动页面其余区域（词云、标签）
                                          if (data.containsKey('keywords') && data['keywords'] is Map) {
                                            final kws = <String, int>{};
                                            (data['keywords'] as Map).forEach((k, v) {
                                              kws[k.toString()] = int.tryParse(v.toString()) ?? 0;
                                            });
                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              setState(() {
                                                _remoteKeywords = kws;
                                                _remoteScores = scoreKeywords(kws);
                                                _aiProvider = provider;
                                              });
                                            });
                                          }
                                          // seed the chat with initial assistant message
                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            if (_chatMessages.isEmpty) setState(() => _chatMessages.add({'role': 'assistant', 'text': '来源: $provider\n\n$text'}));
                                          });
                                          return const Center(child: Text('已加载 AI 建议，您可以在下方对话框继续询问。', style: TextStyle(color: Colors.grey)));
                                        },
                                      )
                                    : ListView.builder(
                                        controller: _aiScrollController,
                                        itemCount: _chatMessages.length,
                                        itemBuilder: (context, idx) {
                                          final m = _chatMessages[idx];
                                          final isUser = m['role'] == 'user';
                                          return Align(
                                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(color: isUser ? Colors.blue.shade50 : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                              child: Text(m['text'] ?? '', style: TextStyle(color: isUser ? Colors.black87 : Colors.black87)),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _aiInputController,
                                      enabled: !_aiSending,
                                      decoration: const InputDecoration(hintText: '向 AI 提问，例如：如何优化会议？', isDense: true, border: OutlineInputBorder()),
                                      onSubmitted: (v) => _sendAiChat(v),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _aiSending ? null : () => _sendAiChat(_aiInputController.text),
                                    child: _aiSending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('发送'),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                        // === AI_ANALYSIS: UI END ===
                      ]
                    )
                ]
              )
            ),
            const SizedBox(height: 40),
          ]
        )
      ),
    );
  }
}

// 将自定义绘图类放在文件末尾（顶层）
class _PiePainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final List<String> labels;
  _PiePainter({required this.values, required this.colors, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2 - 8;
    final total = values.fold(0.0, (a, b) => a + b);
    double start = -pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * pi;
      paint.color = colors[i % colors.length];
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, true, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarPainter extends CustomPainter {
  final List<double> values;
  final double target;
  _BarPainter({required this.values, this.target = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blue;
    final w = size.width / (values.length * 2 + 1);
    final maxv = values.fold(0.0, (a, b) => a > b ? a : b);
    for (int i = 0; i < values.length; i++) {
      final x = (i * 2 + 1) * w;
      final h = (values[i] / maxv) * size.height;
      canvas.drawRect(Rect.fromLTWH(x, size.height - h, w, h), paint);
    }
    if (target > 0) {
      final tY = size.height - (target / (maxv == 0 ? 1 : maxv)) * size.height;
      final line = Paint()
        ..color = Colors.red
        ..strokeWidth = 2;
      canvas.drawLine(Offset(0, tY), Offset(size.width, tY), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}