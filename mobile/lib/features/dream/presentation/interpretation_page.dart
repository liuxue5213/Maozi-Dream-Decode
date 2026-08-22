import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 梦境解析结果页面
class InterpretationPage extends ConsumerStatefulWidget {
  final int dreamId;

  const InterpretationPage({super.key, required this.dreamId});

  @override
  ConsumerState<InterpretationPage> createState() => _InterpretationPageState();
}

class _InterpretationPageState extends ConsumerState<InterpretationPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _loadInterpretation();
  }

  Future<void> _loadInterpretation() async {
    // TODO: 调用 API 获取解析结果
    // GET /api/v1/dreams/{widget.dreamId} 获取梦境
    // GET /api/v1/interpretations/{id} 获取解析
    
    // 模拟加载
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _result = {
          'summary': '此梦反映了你近期内心的不安与对失控的恐惧，可能与工作或生活中面临的压力事件有关。',
          'symbols': [
            {'element': '坠落', 'meaning': '失控感、恐惧、压力'},
            {'element': '高楼', 'meaning': '目标、地位、压力来源'},
          ],
          'psychology_analysis': '荣格认为，坠落梦常与「阴影原型」相关，代表你正在回避的某些内在恐惧或未被接纳的自我部分。这种梦在压力期尤为常见。',
          'traditional_meaning': '《周公解梦》云：坠崖落树主大败。但现代解梦更倾向于将其视为心理状态的反映，而非预兆。',
          'reality_connection': '最近是否感到某些事情失去了控制？坠落的梦提醒你关注生活中的「支撑点」——你依靠的是什么？',
          'suggestions': [
            '记录下最近让你感到压力的事件，看看是否有共同的主题',
            '尝试「落地练习」：当你感到焦虑时，感受双脚与地面的接触，做 5 次深呼吸',
            '与信任的朋友聊聊你的感受，分享本身就是一种释放',
          ],
        };
      });
    }
  }

  Future<void> _regenerate() async {
    setState(() => _isLoading = true);
    // TODO: 调用重新生成 API
    // POST /api/v1/dreams/{widget.dreamId}/interpretations/regenerate
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已重新生成解析')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('梦境解析'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _regenerate,
            tooltip: '重新生成',
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // TODO: 分享海报
            },
            tooltip: '分享',
          ),
        ],
      ),
      body: _isLoading ? _buildLoading() : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在加载解析结果...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_result == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            const Text('暂无解析结果'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _regenerate,
              child: const Text('重新生成'),
            ),
          ],
        ),
      );
    }

    final symbols = (_result!['symbols'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final suggestions = (_result!['suggestions'] as List?)?.cast<String>() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 主题概述
          _buildSection(
            icon: Icons.lightbulb_outline,
            title: '梦境主题',
            content: _result!['summary'] ?? '',
          ),
          const SizedBox(height: 16),

          // 象征元素
          if (symbols.isNotEmpty) ...[
            _buildSymbolSection(symbols),
            const SizedBox(height: 16),
          ],

          // 心理学视角
          if (_result!['psychology_analysis'] != null) ...[
            _buildSection(
              icon: Icons.psychology_outlined,
              title: '心理学视角',
              content: _result!['psychology_analysis'],
            ),
            const SizedBox(height: 16),
          ],

          // 传统解梦
          if (_result!['traditional_meaning'] != null) ...[
            _buildSection(
              icon: Icons.menu_book_outlined,
              title: '传统解梦',
              content: _result!['traditional_meaning'],
            ),
            const SizedBox(height: 16),
          ],

          // 现实关联
          if (_result!['reality_connection'] != null) ...[
            _buildSection(
              icon: Icons.link_outlined,
              title: '现实关联',
              content: _result!['reality_connection'],
            ),
            const SizedBox(height: 16),
          ],

          // 建议
          if (suggestions.isNotEmpty) ...[
            _buildSuggestions(suggestions),
            const SizedBox(height: 24),
          ],

          // 免责声明
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '⚠️ 本解析由 AI 生成，仅供参考，不构成医疗或心理治疗建议。如有严重心理困扰，请寻求专业心理咨询师帮助。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(content, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildSymbolSection(List<Map<String, dynamic>> symbols) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '象征元素',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...symbols.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      s['element'] ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s['meaning'] ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(List<String> suggestions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tips_and_updates_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '自我觉察建议',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...suggestions.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${entry.key + 1}. ', style: Theme.of(context).textTheme.bodyMedium),
                  Expanded(child: Text(entry.value, style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
