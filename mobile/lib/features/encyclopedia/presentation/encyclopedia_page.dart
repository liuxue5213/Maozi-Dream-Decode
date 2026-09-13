import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dream_decode/features/encyclopedia/data/encyclopedia_repository.dart';
import 'package:dream_decode/features/encyclopedia/data/encyclopedia_model.dart';

/// 解梦百科页面
class EncyclopediaPage extends ConsumerStatefulWidget {
  const EncyclopediaPage({super.key});

  @override
  ConsumerState<EncyclopediaPage> createState() => _EncyclopediaPageState();
}

class _EncyclopediaPageState extends ConsumerState<EncyclopediaPage> {
  final _searchController = TextEditingController();
  final EncyclopediaRepository _repository = EncyclopediaRepository();

  String _selectedCategory = '全部';
  String _searchKeyword = '';
  List<EncyclopediaModel> _allItems = [];
  List<EncyclopediaModel> _filteredItems = [];
  List<String> _categories = ['全部'];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _loadData(); }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final categories = await _repository.fetchCategories();
      final items = await _repository.fetchEncyclopedia();
      if (mounted) { setState(() { _categories = categories; _allItems = items; _filteredItems = items; _isLoading = false; }); }
    } catch (e) {
      if (mounted) { setState(() { _error = e.toString(); _isLoading = false; }); }
    }
  }

  void _filterItems() {
    setState(() {
      _filteredItems = _allItems.where((item) {
        final matchCategory = _selectedCategory == '全部' || item.category == _selectedCategory;
        final matchKeyword = _searchKeyword.isEmpty || item.title.contains(_searchKeyword) || item.brief.contains(_searchKeyword);
        return matchCategory && matchKeyword;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('解梦百科'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off_outlined, size: 56, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 16),
                      const Text('百科加载失败，请检查网络'),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadData, child: const Text('重试')),
                    ],
                  ),
                )
              : Column(children: [
                  Padding(padding: const EdgeInsets.all(16), child: TextField(controller: _searchController, decoration: const InputDecoration(hintText: '搜索梦境符号...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()), onChanged: (v) { setState(() => _searchKeyword = v.trim()); _filterItems(); })),
                  SizedBox(height: 40, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _categories.length, itemBuilder: (c, i) { final cat = _categories[i]; return Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(label: Text(cat), selected: _selectedCategory == cat, onSelected: (v) { setState(() => _selectedCategory = cat); _filterItems(); })); })),
                  Expanded(child: _filteredItems.isEmpty ? const Center(child: Text('没有找到相关词条')) : ListView.builder(itemCount: _filteredItems.length, itemBuilder: (c, i) { final item = _filteredItems[i]; return Card(child: ListTile(title: Text(item.title), subtitle: Text(item.brief, maxLines: 2, overflow: TextOverflow.ellipsis), onTap: () => _showDetail(item))); })),
                ]),
    );
  }

  void _showDetail(EncyclopediaModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        final paragraphs = (item.content ?? '').split('\n\n').where((p) => p.trim().isNotEmpty).toList();
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Chip(
                  label: Text(item.category, style: TextStyle(fontSize: 12, color: colorScheme.onSecondaryContainer)),
                  backgroundColor: colorScheme.secondaryContainer,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(height: 16),
                Text(item.brief, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
                for (final paragraph in paragraphs) ...[
                  const SizedBox(height: 20),
                  ..._buildParagraph(paragraph),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// 把 "传统解读：xxx" 这类带标签的段落渲染成小标题 + 正文
  List<Widget> _buildParagraph(String paragraph) {
    final colorScheme = Theme.of(context).colorScheme;
    final match = RegExp(r'^(传统解读|心理学视角|文化象征|自我觉察建议)：').firstMatch(paragraph);
    if (match == null) {
      return [
        Text(paragraph, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)),
      ];
    }
    final title = match.group(1)!;
    final body = paragraph.substring(match.end);
    return [
      Row(
        children: [
          Icon(Icons.auto_stories_outlined, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
        ],
      ),
      const SizedBox(height: 6),
      Text(body, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)),
    ];
  }
}
