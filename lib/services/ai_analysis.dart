// AI analysis helpers: keyword extraction, scoring and simple MBTI-like analysis.
// Also provides `fetchAiAnalysis` which calls the backend `/api/ai_analyze` endpoint
// and falls back to local analysis if the network call fails.
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api.dart';
Map<String, int> extractKeywords(String text) {
  final words = RegExp(r"[\u4e00-\u9fa5_a-zA-Z0-9]+")
      .allMatches(text)
      .map((m) => m.group(0)!.toLowerCase())
      .where((w) => w.length > 1)
      .toList();

  final freq = <String, int>{};
  for (var w in words) {
    freq[w] = (freq[w] ?? 0) + 1;
  }
  return freq;
}

Map<String, double> scoreKeywords(Map<String, int> freq) {
  final Map<String, double> score = {};
  final maxv = freq.values.isEmpty ? 1 : freq.values.reduce((a, b) => a > b ? a : b);
  freq.forEach((k, v) {
    score[k] = v / maxv; // normalize to 0..1
  });
  return score;
}

String aiAnalysis(Map<String, int> freq) {
  final high = freq.entries.where((e) => e.value >= 2).map((e) => e.key).toList();
  final List<String> lines = [];
  if (high.any((w) => w.contains('会议') || w.contains('沟通'))) {
    lines.add('行为特征：偏向协作与沟通。建议：减少会议时长并明确议程。');
  }
  if (high.any((w) => w.contains('文档') || w.contains('设计') || w.contains('调研'))) {
    lines.add('行为特征：偏向独立执行与研究。建议：安排更多同步时间以便让产出落地。');
  }
  if (lines.isEmpty) lines.add('行为特征：均衡。建议：保持当前工作方式并关注关键阻塞项。');
  return lines.join('\n');
}

String keywordDetail(String word, String logs) {
  final freq = extractKeywords(logs)[word] ?? 0;
  return '出现次数：$freq\n关联任务：示例任务 A、示例任务 B';
}

// Attempt to fetch AI analysis from backend. Returns the analysis string.
// Throws on network or unexpected errors so callers can fallback if needed.
Future<String> fetchAiAnalysis(String text) async {
  final base = Api.baseUrl();
  final url = Uri.parse('$base/api/ai_analyze');
  try {
    final resp = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'text': text})).timeout(const Duration(seconds: 15));
    if (resp.statusCode == 200) {
      final j = jsonDecode(resp.body);
      if (j is Map && j.containsKey('code') && j['code'] == 0) {
        final data = j['data'];
        // data may be a dict with analysis field, or direct provider response
        if (data is Map && data.containsKey('analysis')) return data['analysis'].toString();
        // if provider returned a string directly
        if (data is String) return data;
        // fallback: try to stringify
        return jsonEncode(data);
      } else if (j is Map && j.containsKey('data')) {
        return j['data'].toString();
      } else {
        throw Exception('Unexpected response: ${resp.body}');
      }
    } else {
      throw Exception('AI API HTTP ${resp.statusCode}: ${resp.body}');
    }
  } catch (e) {
    // bubble up the error for caller to decide fallback
    rethrow;
  }
}

/// Fetch raw AI analysis response as a Map. Returns {'analysis': str, 'provider': optional, ...}
/// Fetch raw AI analysis response as a Map. You can pass either a plain `text`
/// or a `messages` list (for multi-turn conversation). Returns
/// {'analysis': str, ...}
Future<Map<String, dynamic>> fetchAiAnalysisRaw(String text, {List<Map<String, String>>? messages}) async {
  final base = Api.baseUrl();
  final url = Uri.parse('$base/api/ai_analyze');
  final body = messages != null ? {'messages': messages, 'model': ''} : {'text': text};
  try {
    final resp = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body)).timeout(const Duration(seconds: 15));
    if (resp.statusCode == 200) {
      final j = jsonDecode(resp.body);
      if (j is Map && j['code'] == 0 && j.containsKey('data')) {
        final data = j['data'];
        if (data is Map) {
          // prefer analysis field
          final analysis = data['analysis'] ?? data.toString();
          final result = <String, dynamic>{'analysis': analysis};
          // include other fields if present
          data.forEach((k, v) {
            if (k != 'analysis') result[k] = v;
          });
          return result;
        }
        // data is a string or other type
        return {'analysis': data.toString()};
      }
      throw Exception('Unexpected response: ${resp.body}');
    }
    throw Exception('AI API HTTP ${resp.statusCode}: ${resp.body}');
  } catch (e) {
    rethrow;
  }
}
