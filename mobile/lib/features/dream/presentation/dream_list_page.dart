import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dream_decode/features/dream/data/dream_repository.dart';
import 'package:dream_decode/features/dream/data/dream_model.dart';

/// 梦境列表页面 - 首页
class DreamListPage extends ConsumerStatefulWidget {
  const DreamListPage({super.key});

  @override
  ConsumerState<DreamListPage> createState() => _DreamListPageState();
}

class _DreamListPageState extends ConsumerState<DreamListPage> {
  final DreamRepository _repository = DreamRepository();
  List<DreamModel> _dreams = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDreams();
  }

  Future<void> _loadDreams() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dreams = await _repository.fetchDreams();
      if (mounted) {
        setState(() {
          _dreams = dreams;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的梦'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDreams,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/record'),
        icon: const Icon(Icons.add),
        label: const Text('记梦'),
      ),
    );
  }

  Future<void> _deleteDream(DreamModel dream) async {
    await _repository.deleteDream(dream.id);
    if (mounted) {
      setState(() => _dreams.remove(dream));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('梦境已删除'),
          action: SnackBarAction(
            label: '撤销',
            onPressed: () async {
              await _repository.createDream(
                content: dream.content,
                emotions: dream.emotions,
                scenes: dream.scenes,
                date: dream.date,
              );
              _loadDreams();
            },
          ),
        ),
      );
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('加载中...'),
          ],
        ),
      );
    }

    if (_dreams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.nightlight_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '还没有记录过梦境',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击下方「记梦」开始记录你的第一个梦',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDreams,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _dreams.length,
        itemBuilder: (context, index) {
          final dream = _dreams[index];
          return Dismissible(
            key: Key(dream.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            onDismissed: (_) => _deleteDream(dream),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                dream.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(dream.date),
                  if (dream.emotions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: dream.emotions.map((e) => Chip(
                        label: Text(e, style: const TextStyle(fontSize: 12)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ),
                  ],
                ],
              ),
              onTap: () => context.push('/dream/${dream.id}'),
            ),
          ),
          );
        },
      ),
    );
  }
}
