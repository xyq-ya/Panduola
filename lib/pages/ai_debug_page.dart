import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/ai_analysis.dart';

class AiDebugPage extends StatefulWidget {
  const AiDebugPage({super.key});

  @override
  State<AiDebugPage> createState() => _AiDebugPageState();
}

class _AiDebugPageState extends State<AiDebugPage> {
  final TextEditingController _controller = TextEditingController(
      text: '今天团队讨论了很多会议和沟通问题，需要改进');
  bool _loading = false;
  String? _analysis;
  String? _raw;
  String? _error;

  Future<void> _runAnalysis() async {
    setState(() {
      _loading = true;
      _analysis = null;
      _raw = null;
      _error = null;
    });
    try {
      final text = _controller.text;
      final Map<String, dynamic> res = await fetchAiAnalysisRaw(text);
      setState(() {
        _analysis = res['analysis']?.toString() ?? null;
        // Keep raw if present
        final r = Map.of(res);
        _raw = const JsonEncoder.withIndent('  ').convert(r);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 调试'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '发送给 AI 的文本',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loading ? null : _runAnalysis,
              icon: const Icon(Icons.analytics),
              label: const Text('运行分析'),
            ),
            const SizedBox(height: 12),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null) ...[
              Text('错误: $_error', style: const TextStyle(color: Colors.red)),
            ],
            if (_analysis != null) ...[
              const Text('分析结果:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(_analysis!),
            ],
            const SizedBox(height: 12),
            if (_raw != null) ...[
              const Text('原始响应 (raw):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_raw!, style: const TextStyle(fontFamily: 'monospace')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
