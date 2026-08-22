import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // TODO: 调用真实 API 保存梦境并触发解析
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('梦境已保存，解析完成！')),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记录梦境'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 梦境描述输入
              Text(
                '昨晚你梦见了什么？',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: '尽量详细地描述你的梦境，至少 5 个字...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入梦境描述';
                  }
                  if (value.trim().length < 5) {
                    return '梦境描述至少需要 5 个字';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 日期选择
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '梦境日期',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 24),

              // 情绪标签
              Text(
                '情绪感受（可多选）',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _emotions.map((emotion) {
                  final selected = _selectedEmotions.contains(emotion);
                  return FilterChip(
                    label: Text(emotion),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selectedEmotions.add(emotion);
                        } else {
                          _selectedEmotions.remove(emotion);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 场景标签
              Text(
                '场景元素（可多选）',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _scenes.map((scene) {
                  final selected = _selectedScenes.contains(scene);
                  return FilterChip(
                    label: Text(scene),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selectedScenes.add(scene);
                        } else {
                          _selectedScenes.remove(scene);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // 提交按钮
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('正在解析...'),
                          ],
                        )
                      : const Text('保存并解析', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),

              // 免责声明
              Text(
                'AI 解析结果仅供参考，不构成医疗或心理治疗建议',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
