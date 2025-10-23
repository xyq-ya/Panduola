// AI analysis helpers: keyword extraction, scoring and simple MBTI-like analysis.
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
