import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:dream_decode/features/dream/data/dream_repository.dart';
import 'package:dream_decode/features/dream/data/dream_model.dart';

/// 梦境详情页面 - 显示梦境内容和AI解析结果（流式打字机效果）
class DreamDetailPage extends ConsumerStatefulWidget {
  final String dreamId;

  const DreamDetailPage({super.key, required this.dreamId});

  @override
  ConsumerState<DreamDetailPage> createState() => _DreamDetailPageState();
}

class _DreamDetailPageState extends ConsumerState<DreamDetailPage> {
  final DreamRepository _repository = DreamRepository();
  final ScrollController _scrollController = ScrollController();
  DreamModel? _dream;
  bool _isLoading = true;
  bool _isInterpreting = false;
  bool _disposed = false;
  String? _interpretation;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDream();
  }

  @override
  void dispose() {
    _disposed = true;
    _scrollController.dispose();
    super.dispose();
  }

  /// 把 "Exception: xxx" 还原成用户可读的中文提示
  String _friendly(Object e) => e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

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

  /// 流式解析：边生成边渲染，完成后回退到非流式接口重试一次
  Future<void> _startInterpretation() async {
    if (_dream == null || _isInterpreting) return;

    setState(() {
      _isInterpreting = true;
      _error = null;
      _interpretation ??= '';
    });

    final buffer = StringBuffer();
    String? failureMessage;
    try {
      await for (final delta in _repository.interpretDreamStream(_dream!.id)) {
        if (_disposed) return;
        buffer.write(delta);
        if (mounted) {
          setState(() => _interpretation = buffer.toString());
          _scrollToBottom();
        }
      }
      if (buffer.toString().trim().isEmpty) {
        throw Exception('AI 没有返回解析内容');
      }
      await _repository.saveInterpretation(_dream!.id, buffer.toString());
      if (!mounted) return;
      setState(() => _isInterpreting = false);
    } catch (streamError) {
      print('流式解析失败，回退到非流式: $streamError');
      failureMessage = _friendly(streamError);
      try {
        final result = await _repository.interpretDream(_dream!.id);
        if (!mounted) return;
        setState(() {
          _interpretation = result;
          _isInterpreting = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isInterpreting = false;
          _interpretation = null;
          _error = failureMessage;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
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

    if (_dream == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('加载失败'),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _friendly(_error!),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadDream, child: const Text('重试')),
          ],
        ),
      );
    }

    return ListView(
      controller: _scrollController,
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
        ] else if (_error != null) ...[
          _buildErrorCard(),
        ] else ...[
          _buildStartInterpretationCard(),
        ],
      ],
    );
  }

  Widget _buildInterpretationCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome,
                     color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'AI 梦境解析',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (_isInterpreting)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
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
                blockquote: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
                blockquoteDecoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(color: colorScheme.primary, width: 3)),
                ),
                listBullet: const TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI 解析结果仅供参考，不构成医疗或心理治疗建议',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterpretingCard() {
    final colorScheme = Theme.of(context).colorScheme;
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
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _startInterpretation,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartInterpretationCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 64,
              color: colorScheme.outline,
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
                color: colorScheme.onSurfaceVariant,
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
