import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 解梦百科页面
class EncyclopediaPage extends ConsumerStatefulWidget {
  const EncyclopediaPage({super.key});

  @override
  ConsumerState<EncyclopediaPage> createState() => _EncyclopediaPageState();
}

class _EncyclopediaPageState extends ConsumerState<EncyclopediaPage> {
  final _searchController = TextEditingController();
  String _selectedCategory = '全部';
  String _searchKeyword = '';

  static const _categories = ['全部', '动物', '自然', '身体', '场景', '事件', '颜色'];

  // 示例数据，实际应从 API 获取: GET /api/v1/encyclopedia/search?keyword=xxx&category=xxx
  static const _allItems = [
    {'title': '蛇', 'category': '动物', 'brief': '财运、转变、潜意识的力量'},
    {'title': '掉牙', 'category': '身体', 'brief': '失控感、外貌焦虑'},
    {'title': '飞翔', 'category': '场景', 'brief': '自由、逃离、自信'},
    {'title': '坠落', 'category': '场景', 'brief': '失控、焦虑、不安全感'},
    {'title': '水', 'category': '自然', 'brief': '情绪、潜意识、净化'},
    {'title': '死亡', 'category': '事件', 'brief': '结束与新生、转变'},
    {'title': '考试', 'category': '事件', 'brief': '自我怀疑、被审视感'},
    {'title': '追逐', 'category': '事件', 'brief': '逃避、压力、面对'},
    {'title': '车祸', 'category': '事件', 'brief': '失控、偏离轨道'},
    {'title': '结婚', 'category': '事件', 'brief': '结合、承诺、新的开始'},
    {'title': '火', 'category': '自然', 'brief': '激情、愤怒、毁灭与重生'},
    {'title': '下雨', 'category': '自然', 'brief': '情绪宣泄、净化、忧郁'},
    {'title': '狗', 'category': '动物', 'brief': '忠诚、友谊、保护'},
    {'title': '猫', 'category': '动物', 'brief': '独立、神秘、直觉'},
    {'title': '钱', 'category': '事件', 'brief': '自我价值、安全感'},
    {'title': '电梯', 'category': '场景', 'brief': '阶层流动、心态升降'},
    {'title': '迷路', 'category': '场景', 'brief': '人生方向缺失、选择困惑'},
    {'title': '迷失', 'category': '场景', 'brief': '迷茫感、身份认同危机'},
    {'title': '迟到', 'category': '事件', 'brief': '时间焦虑、错过恐惧'},
    {'title': '跌落', 'category': '场景', 'brief': '失败恐惧、地位下降'},
  ];

  /// 根据分类和搜索关键词过滤数据
  List<Map<String, String>> get _filteredItems {
    return _allItems.where((item) {
      final matchCategory = _selectedCategory == '全部' || item['category'] == _selectedCategory;
      final matchKeyword = _searchKeyword.isEmpty || 
          item['title']!.contains(_searchKeyword) || 
          item['brief']!.contains(_searchKeyword);
      return matchCategory && matchKeyword;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('解梦百科'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索梦境符号，如：蛇、飞翔、掉牙...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchKeyword.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchKeyword = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                setState(() => _searchKeyword = value.trim());
              },
            ),
          ),

          // 分类筛选
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final selected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (value) {
                      setState(() => _selectedCategory = category);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // 结果统计
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '共 ${filteredItems.length} 个词条',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 词条列表
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 8),
                        Text(
                          '没有找到相关词条',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return Card(
                        child: ListTile(
                          title: Text(item['title']!),
                          subtitle: Text(item['brief']!),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item['category']!,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () => _showItemDetail(context, item['title']!, item['brief']!),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showItemDetail(BuildContext context, String title, String brief) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: controller,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Text(brief, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              const Text('详细内容待从 API 加载...'),
            ],
          ),
        ),
      ),
    );
  }
}
