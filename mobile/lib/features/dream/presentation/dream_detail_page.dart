import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:dream_decode/features/dream/data/dream_repository.dart';
import 'package:dream_decode/features/dream/data/dream_model.dart';

/// 梦境详情页面 - 显示梦境内容和AI解析结果
class DreamDetailPage extends ConsumerStatefulWidget {
  final String dreamId;

  const DreamDetailPage({super.key, required this.dreamId});

  @override
  ConsumerState<DreamDetailPage> createState() => _DreamDetailPageState();
}

class _DreamDetailPageState extends ConsumerState<DreamDetailPage> {
  final DreamRepository _repository = DreamRepository();
  DreamModel? _dream;
  bool _isLoading = true;
  bool _isInterpreting = false;
  String? _interpretation;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDream();
  }

  Future<void> _loadDream() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      var dream = await _repository.getDreamDetail(widget.dreamId);

      // 服务器已有解析但本地未缓存 -> 自动拉取展示
      if (dream != null &&
          (dream.interpretation == null || dream.interpretation!.isEmpty) &&
          dream.hasInterpretation) {
        final existing = await _repository.getLatestInterpretation(
          dream.serverId?.toString() ?? widget.dreamId.replaceFirst('srv_', ''),
        );
        if (existing != null && existing.isNotEmpty) {
          dream = DreamModel(
            id: dream.id,
            content: dream.content,
            createdAt: dream.createdAt,
            emotions: dream.emotions,
            scenes: dream.scenes,
            date: dream.date,
            interpretation: existing,
            hasInterpretation: true,
          );
        }
      }

      if (mounted) {
        setState(() {
          _dream = dream;
          _interpretation = dream?.interpretation;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除梦境'),
        content: const Text('删除后无法恢复，确定要删除这条梦境记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.deleteDream(widget.dreamId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('梦境已删除')),
        );
        context.pop();
      }
    }
  }

  Future<void> _startInterpretation() async {
    if (_dream == null) return;

    setState(() => _isInterpreting = true);

    try {
      final result = await _repository.interpretDream(_dream!.id);
      if (mounted) {
        setState(() {
          _interpretation = result;
          _isInterpreting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInterpreting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('解析失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('梦境详情'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _dream == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('加载失败'),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadDream, child: const Text('重试')),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 梦境信息卡片
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.nightlight_round, 
                         color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      _dream!.date,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _dream!.content,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (_dream!.emotions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _dream!.emotions
                        .map((e) => Chip(label: Text(e)))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // AI解析结果
        if (_interpretation != null && _interpretation!.isNotEmpty) ...[
          _buildInterpretationCard(),
        ] else if (_isInterpreting) ...[
          _buildInterpretingCard(),
        ] else ...[
          _buildStartInterpretationCard(),
        ],
      ],
    );
  }

  Widget _buildInterpretationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, 
                     color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'AI 梦境解析',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            MarkdownBody(
              data: _interpretation!,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                p: const TextStyle(fontSize: 15, height: 1.6),
                blockquote: const TextStyle(
                  fontSize: 14, 
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
                blockquoteDecoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                listBullet: const TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI 解析结果仅供参考，不构成医疗或心理治疗建议',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterpretingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'AI 正在解析你的梦境...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '深度分析需要一些时间，请稍候',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartInterpretationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '还没有解析结果',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '让 AI 从心理学和传统文化角度\n深度解析这个梦境',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _startInterpretation,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('开始 AI 解析'),
            ),
          ],
        ),
      ),
    );
  }
}
