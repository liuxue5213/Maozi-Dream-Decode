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
      body: _isLoading ? const Center(child: CircularProgressIndicator()) :
        _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('加载失败'), Text(_error!), ElevatedButton(onPressed: _loadData, child: const Text('重试'))])) :
        Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: TextField(controller: _searchController, decoration: const InputDecoration(hintText: '搜索梦境符号...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()), onChanged: (v) { setState(() => _searchKeyword = v.trim()); _filterItems(); })),
          SizedBox(height: 40, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _categories.length, itemBuilder: (c, i) { final cat = _categories[i]; return Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(label: Text(cat), selected: _selectedCategory == cat, onSelected: (v) { setState(() => _selectedCategory = cat); _filterItems(); })); })),
          Expanded(child: _filteredItems.isEmpty ? const Center(child: Text('没有找到相关词条')) : ListView.builder(itemCount: _filteredItems.length, itemBuilder: (c, i) { final item = _filteredItems[i]; return Card(child: ListTile(title: Text(item.title), subtitle: Text(item.brief), onTap: () => showModalBottomSheet(context: c, builder: (c) => Container(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 16), Text(item.brief), if (item.content != null) ...[const SizedBox(height: 16), Text(item.content!)]]))))); })),
        ]),
    );
  }
}
