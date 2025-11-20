import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/ai_analysis.dart';
import '../services/data_service.dart';

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  int? _userId;
  Future<Map<String, dynamic>>? _aiFutureMap;
  Map<String, int>? _remoteKeywords;
  Map<String, double>? _remoteScores;
  String _aiProvider = 'local';

  // 数据库数据状态
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _hasInitialLoad = false;

  // 从数据库加载数据的方法
  Future<void> _loadDashboardData() async {
    if (_userId == null) {
      setState(() {
        _errorMessage = '用户未登录，无法加载数据';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      print('开始加载仪表盘数据，用户ID: $_userId');
      final data = await DataService.getDashboardStats(_userId!)
          .timeout(const Duration(seconds: 30));
      
      print('仪表盘数据加载成功: $data');
      setState(() {
        _dashboardData = data;
        _isLoading = false;
        _hasInitialLoad = true;
      });
    } catch (e) {
      print('加载仪表盘数据失败: $e');
      setState(() {
        _isLoading = false;
        _hasInitialLoad = true;
        _errorMessage = _getErrorMessage(e);
      });
    }
  }

  // 错误信息处理
  String _getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return '数据库连接超时，请检查网络连接';
    } else if (error.toString().contains('Connection refused') ||
        error.toString().contains('Failed host lookup')) {
      return '无法连接到数据库服务器';
    } else if (error.toString().contains('401') ||
        error.toString().contains('403')) {
      return '用户权限不足，无法访问数据';
    } else {
      return '数据库连接失败: ${error.toString()}';
    }
  }

  void _refreshAi() {
    setState(() {
      _aiFutureMap = fetchAiAnalysisRaw(_sampleLogs).then((data) {
        try { 
          print('fetchAiAnalysisRaw success, provider=${data['provider']}'); 
        } catch (_) {}
        
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
          _remoteScores = _remoteKeywords != null ? _scoreKeywords(_remoteKeywords!) : null;
          _aiProvider = data['provider']?.toString() ?? 'remote';
        });
        return data;
      }).catchError((e) async {
        try { 
          print('fetchAiAnalysisRaw failed: $e'); 
        } catch (_) {}
        
        final localMap = extractKeywords(_sampleLogs);
        setState(() {
          _remoteKeywords = localMap;
          _remoteScores = _scoreKeywords(localMap);
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
      final messages = _chatMessages.map<Map<String, String>>((msg) => 
        <String, String>{
          'role': msg['role'] ?? 'user',
          'content': msg['text'] ?? '',
        }
      ).toList();
      
      final resp = await fetchAiAnalysisRaw('', messages: messages).timeout(const Duration(seconds: 30));
      final assistant = resp['analysis']?.toString() ?? '（无回复）';
      setState(() {
        _chatMessages.add({'role': 'assistant', 'text': assistant});
      });
    } catch (e) {
      final fallback = aiAnalysis(extractKeywords(text));
      setState(() {
        _chatMessages.add({'role': 'assistant', 'text': fallback});
      });
    } finally {
      setState(() {
        _aiSending = false;
      });
      await Future.delayed(const Duration(milliseconds: 100));
      if (_aiScrollController.hasClients) {
        _aiScrollController.animateTo(
          _aiScrollController.position.maxScrollExtent, 
          duration: const Duration(milliseconds: 200), 
          curve: Curves.easeOut
        );
      }
    }
  }

  final String _sampleLogs = '''
周一: 与产品讨论需求，会议 2 小时；完成接口文档编写；
周二: 代码实现模块 A，单元测试覆盖 80%；部署到测试环境；
周三: 调研第三方 SDK，处理线上异常；修复 bug；
周四: 团队同步会议，设计评审；文档整理；
周五: 优化性能，压测，准备下周计划；
''';

  // 本地关键词评分方法
  Map<String, double> _scoreKeywords(Map<String, int> freq) {
    if (freq.isEmpty) return {};
    final maxValue = freq.values.reduce((a, b) => a > b ? a : b).toDouble();
    final scores = <String, double>{};
    freq.forEach((key, value) {
      final logValue = log(value + 1);
      final logMax = log(maxValue + 1);
      final normalized = logValue / logMax;
      scores[key] = 0.1 + normalized * 0.9;
    });
    return scores;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_userId == null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _userId = userProvider.id;
      print('页面获取的用户 id：$_userId');
      
      if (!_hasInitialLoad) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadDashboardData();
          _refreshAi();
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.id != null) {
        setState(() {
          _userId = userProvider.id;
        });
      }
    });
  }

  // 词云构建方法
  Widget _buildWordCloud() {
    if (_isLoading && _dashboardData == null) {
      return _buildLoadingWidget('正在加载关键词数据...');
    }
    
    if (_dashboardData == null) {
      return _buildNoDataWidget('等待数据库连接...');
    }
    
    final keywordMap = _dashboardData?['keywords'] as Map<String, dynamic>?;
    
    if (keywordMap == null || keywordMap.isEmpty) {
      return _buildNoDataWidget('暂无关键词数据');
    }
    
    final scores = _convertKeywordsToScores(keywordMap);
    
    final sortedEntries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topKeywords = sortedEntries.take(20).toList(); // 限制数量防止超距
    
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 120,
        maxHeight: 200, // 限制最大高度
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(12)
        ),
        child: SingleChildScrollView( // 添加滚动防止超距
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: topKeywords.map((e) {
              final size = 12 + (e.value * 20); // 减小字体大小范围
              final color = Colors.primaries[e.key.hashCode % Colors.primaries.length];
              return GestureDetector(
                onTap: () => _showKeywordDetail(e.key),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    e.key, 
                    style: TextStyle(
                      fontSize: size, 
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // 加载中的显示组件
  Widget _buildLoadingWidget(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12)
      ),
      child: Column(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 关键词分数转换方法
  Map<String, double> _convertKeywordsToScores(Map<String, dynamic> keywordMap) {
    if (keywordMap.isEmpty) return {};
    
    final values = keywordMap.values.cast<int>().toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b).toDouble();
    
    final scores = <String, double>{};
    keywordMap.forEach((key, value) {
      final logValue = log(value + 1);
      final logMax = log(maxValue + 1);
      final normalized = logValue / logMax;
      scores[key] = 0.1 + normalized * 0.9;
    });
    
    return scores;
  }

  // 无数据时的显示组件
  Widget _buildNoDataWidget(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12)
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh),
            label: const Text('重新连接'),
          ),
        ],
      ),
    );
  }

  void _showKeywordDetail(String word) {
    final keywordMap = _dashboardData?['keywords'] as Map<String, dynamic>?;
    final count = keywordMap?[word] ?? 0;
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('关键词分析: $word'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('出现次数: $count'),
            const SizedBox(height: 8),
            if (_dashboardData != null)
              const Text('数据来源: 实时数据库'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('关闭')
          ),
        ],
      ),
    );
  }

  // 饼图构建方法 - 修复数据格式问题
  Widget _buildPieChart() {
    if (_isLoading && _dashboardData == null) {
      return _buildLoadingWidget('正在加载分类数据...');
    }
    
    if (_dashboardData == null) {
      return _buildNoDataWidget('等待数据库连接...');
    }
    
    final categoryData = _dashboardData?['category_ratio'] as Map<String, dynamic>?;
    
    if (categoryData == null || categoryData.isEmpty) {
      return _buildNoDataWidget('暂无分类数据');
    }
    
    // 确保数据格式正确
    final List<PieChartItem> chartItems = [];
    final colors = [Colors.blue, Colors.orange, Colors.green, Colors.red, Colors.purple, Colors.teal];
    
    categoryData.forEach((key, value) {
      final double numericValue = (value is int) ? value.toDouble() : 
                                (value is double) ? value : 
                                double.tryParse(value.toString()) ?? 0.0;
      if (numericValue > 0) {
        chartItems.add(PieChartItem(
          label: key,
          value: numericValue,
          color: colors[chartItems.length % colors.length]
        ));
      }
    });
    
    if (chartItems.isEmpty) {
      return _buildNoDataWidget('分类数据为空');
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12)
      ),
      child: Column(
        children: [
          const Text(
            '任务分类耗时占比', 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _PiePainter(items: chartItems),
            ),
          ),
          const SizedBox(height: 16),
          // 图例 - 限制宽度防止超距
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: chartItems.map((item) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: item.color,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${item.label} (${item.value.toInt()}%)',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 柱状图构建方法 - 修复数据格式问题
  Widget _buildBarChart() {
    if (_isLoading && _dashboardData == null) {
      return _buildLoadingWidget('正在加载趋势数据...');
    }
    
    if (_dashboardData == null) {
      return _buildNoDataWidget('等待数据库连接...');
    }
    
    final trendData = _dashboardData?['trend'] as List<dynamic>?;
    
    if (trendData == null || trendData.isEmpty) {
      return _buildNoDataWidget('暂无趋势数据');
    }
    
    // 处理趋势数据
    final List<BarChartItem> barItems = [];
    
    for (var item in trendData) {
      if (item is Map<String, dynamic>) {
        final date = item['date']?.toString() ?? '';
        final count = (item['count'] is int) ? item['count'] as int : 
                     (item['count'] is double) ? (item['count'] as double).toInt() :
                     int.tryParse(item['count'].toString()) ?? 0;
        
        if (date.isNotEmpty && count > 0) {
          barItems.add(BarChartItem(date: date, value: count.toDouble()));
        }
      }
    }
    
    if (barItems.isEmpty) {
      return _buildNoDataWidget('趋势数据格式错误');
    }
    
    // 限制显示数量，防止超距
    final displayItems = barItems.length > 7 ? barItems.sublist(0, 7) : barItems;
    final maxValue = displayItems.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '工作效率趋势（近7天）', 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
          ),
          const SizedBox(height: 16),
          
          // 柱状图容器
          Container(
            height: 150,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: displayItems.map((item) {
                final height = (item.value / (maxValue > 0 ? maxValue : 1)) * 80;
                final isAboveTarget = item.value >= (maxValue * 0.8);
                
                return Flexible( // 使用Flexible防止超距
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.value.toInt().toString(), 
                        style: TextStyle(
                          fontSize: 10,
                          color: isAboveTarget ? Colors.green : Colors.grey,
                        )
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 24,
                        height: height,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isAboveTarget ? Colors.green : Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              isAboveTarget ? Colors.green.shade600 : Colors.blue.shade600,
                              isAboveTarget ? Colors.green.shade400 : Colors.blue.shade400,
                            ]
                          )
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 60),
                        child: Text(
                          _formatDate(item.date), 
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          
          // 图例说明
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.blue, '正常'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.green, '超过目标'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  // 辅助方法：格式化日期显示
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;
      
      if (difference == 0) return '今天';
      if (difference == 1) return '昨天';
      if (difference < 7) return '${difference}天前';
      
      return '${date.month}/${date.day}';
    } catch (e) {
      // 如果解析失败，尝试其他格式或返回原始字符串
      if (dateStr.length >= 10) {
        return dateStr.substring(5, 10); // 返回 MM-DD 格式
      }
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // 数据库连接状态指示器
              if (_errorMessage.isNotEmpty || _isLoading)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _errorMessage.isNotEmpty ? Colors.orange[50] : Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _errorMessage.isNotEmpty ? Colors.orange : Colors.blue,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _errorMessage.isNotEmpty ? Icons.warning : Icons.info,
                        color: _errorMessage.isNotEmpty ? Colors.orange[700] : Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage.isNotEmpty 
                              ? _errorMessage
                              : '正在加载数据...',
                          style: TextStyle(
                            color: _errorMessage.isNotEmpty ? Colors.orange[700] : Colors.blue[700],
                          ),
                        ),
                      ),
                      if (_errorMessage.isNotEmpty)
                        IconButton(
                          onPressed: _loadDashboardData,
                          icon: const Icon(Icons.refresh),
                          color: Colors.orange[700],
                        ),
                    ],
                  ),
                ),

              // 关键词分析卡片
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(12), 
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('关键词分析', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 8),
                        if (_dashboardData != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '实时数据',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildWordCloud(),
                  ],
                ),
              ),

              // 饼图和柱状图卡片
              Column(
                children: [
                  // 饼图卡片
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(12), 
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]
                    ),
                    child: _buildPieChart(),
                  ),
                  
                  // 柱状图卡片
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(12), 
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]
                    ),
                    child: _buildBarChart(),
                  ),
                ],
              ),

              // AI分析卡片
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(12), 
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('AI 智能分析', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Row(
                          children: [
                            Text('来源: $_aiProvider', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                _loadDashboardData();
                                _refreshAi();
                              },
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('刷新数据'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 260,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50], 
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: _chatMessages.isEmpty
                                ? FutureBuilder<Map<String, dynamic>>(
                                    future: _aiFutureMap,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
                                      if (snapshot.hasError || snapshot.data == null) {
                                        final freq = _remoteKeywords ?? extractKeywords(_sampleLogs);
                                        final local = aiAnalysis(freq);
                                        return SingleChildScrollView(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0), 
                                            child: Text(local),
                                          ),
                                        );
                                      }
                                      final data = snapshot.data!;
                                      final text = data['analysis']?.toString() ?? '暂无分析结果';
                                      return SingleChildScrollView(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(text),
                                        ),
                                      );
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
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                                          ),
                                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isUser ? Colors.blue.shade50 : Colors.grey.shade100, 
                                            borderRadius: BorderRadius.circular(8)
                                          ),
                                          child: Text(
                                            m['text'] ?? '', 
                                            style: const TextStyle(fontSize: 14),
                                          ),
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
                                  decoration: const InputDecoration(
                                    hintText: '向 AI 提问...', 
                                    isDense: true, 
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onSubmitted: (v) => _sendAiChat(v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _aiSending ? null : () => _sendAiChat(_aiInputController.text),
                                child: _aiSending 
                                    ? const SizedBox(
                                        width: 16, 
                                        height: 16, 
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ) 
                                    : const Text('发送'),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 饼图数据模型
class PieChartItem {
  final String label;
  final double value;
  final Color color;
  
  PieChartItem({
    required this.label,
    required this.value,
    required this.color,
  });
}

// 柱状图数据模型
class BarChartItem {
  final String date;
  final double value;
  
  BarChartItem({
    required this.date,
    required this.value,
  });
}

// 自定义饼图绘图类
class _PiePainter extends CustomPainter {
  final List<PieChartItem> items;
  _PiePainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    final total = items.fold(0.0, (sum, item) => sum + item.value);
    if (total == 0) return;
    
    double startAngle = -pi / 2; // 从12点方向开始
    
    for (final item in items) {
      final sweepAngle = (item.value / total) * 2 * pi;
      
      paint.color = item.color;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}