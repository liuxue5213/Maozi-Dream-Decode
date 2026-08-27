import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:dream_decode/core/network/dio_client.dart';

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
    try {
      final response = await DioClient().dio.get('dreams/${widget.dreamId}/interpretations');
      final interpretations = response.data as List<dynamic>;
      final result = interpretations.isEmpty
          ? null
          : (interpretations.first as Map<String, dynamic>)['result_json'];
      if (mounted) {
        setState(() {
          _isLoading = false;
          _result = result is Map<String, dynamic> ? result : {'content': result?.toString()};
        });
      }
    } catch (e) {
      if (mounted) {
      setState(() {
        _isLoading = false;
        _result = null;
      });
      }
    }
  }

  Future<void> _regenerate() async {
    setState(() => _isLoading = true);
    try {
      final response = await DioClient().dio.post('dreams/${widget.dreamId}/interpretations/regenerate');
      if (mounted) {
        setState(() {
          _result = (response.data as Map<String, dynamic>)['result_json'] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已重新生成解析')),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('重新生成失败：$e')));
      }
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('分享海报功能即将推出')),
              );
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

    final markdown = _result!['content']?.toString();
    if (markdown != null && markdown.isNotEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: MarkdownBody(data: markdown),
          ),
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
