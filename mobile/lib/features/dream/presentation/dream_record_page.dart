import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dream_decode/features/dream/data/dream_repository.dart';
import 'package:dream_decode/features/dream/data/dream_model.dart';

/// 梦境记录页面
class DreamRecordPage extends ConsumerStatefulWidget {
  const DreamRecordPage({super.key});

  @override
  ConsumerState<DreamRecordPage> createState() => _DreamRecordPageState();
}

class _DreamRecordPageState extends ConsumerState<DreamRecordPage> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final List<String> _selectedEmotions = [];
  final List<String> _selectedScenes = [];
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  static const _emotions = ['恐惧', '焦虑', '开心', '悲伤', '愤怒', '平静', '困惑', '兴奋'];
  static const _scenes = ['飞翔', '坠落', '追逐', '迷路', '水', '火', '学校', '工作', '家乡', '陌生'];

  @override
  void dispose() { _contentController.dispose(); super.dispose(); }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime.now());
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final repository = DreamRepository();
      await repository.createDream(content: _contentController.text.trim(), emotions: _selectedEmotions, scenes: _selectedScenes, date: DateFormat('yyyy-MM-dd').format(_selectedDate));
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('梦境已保存！'))); context.go('/'); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('提交失败: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('记录梦境'), centerTitle: true),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('昨晚你梦见了什么？', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(controller: _contentController, maxLines: 8, decoration: const InputDecoration(hintText: '尽量详细地描述你的梦境，至少 5 个字...', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? '请输入梦境描述' : (v.trim().length < 5 ? '至少5个字' : null)),
            const SizedBox(height: 16),
            InkWell(onTap: _selectDate, child: InputDecorator(decoration: const InputDecoration(labelText: '梦境日期', border: OutlineInputBorder()), child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)))),
            const SizedBox(height: 24),
            const Text('情绪感受（可多选）', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: _emotions.map((e) => FilterChip(label: Text(e), selected: _selectedEmotions.contains(e), onSelected: (v) => setState(() { if (v) { _selectedEmotions.add(e); } else { _selectedEmotions.remove(e); } })).toList()),
            const SizedBox(height: 24),
            const Text('场景元素（可多选）', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: _scenes.map((s) => FilterChip(label: Text(s), selected: _selectedScenes.contains(s), onSelected: (v) => setState(() { if (v) { _selectedScenes.add(s); } else { _selectedScenes.remove(s); } })).toList()),
            const SizedBox(height: 32),
            FilledButton(onPressed: _isSubmitting ? null : _submit, child: Padding(padding: const EdgeInsets.all(16), child: _isSubmitting ? const CircularProgressIndicator() : const Text('保存梦境'))),
          ]),
        ),
      ),
    );
  }
}
