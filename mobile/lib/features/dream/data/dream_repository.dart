// 梦境仓库 - API优先，本地存储后备
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dream_decode/core/network/dio_client.dart';
import 'package:dream_decode/core/env.dart';
import 'dream_model.dart';
import 'local_dream_storage.dart';

class DreamRepository {
  final DioClient _dioClient = DioClient();

  /// 获取所有梦境列表（API优先，本地后备）
  Future<List<DreamModel>> fetchDreams() async {
    try {
      final response = await _dioClient.dio.get(
        '/api/v1/dreams',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final dreams = data.map((item) => DreamModel.fromJson(item)).toList();
        // 同步到本地
        for (final dream in dreams) {
          await LocalDreamStorage.saveDream(dream);
        }
        return dreams;
      }
    } catch (e) {
      print('API获取梦境失败，使用本地数据: $e');
    }
    
    // API失败，返回本地数据
    return LocalDreamStorage.getDreams();
  }

  /// 获取梦境详情
  Future<DreamModel?> getDreamDetail(String id) async {
    try {
      final response = await _dioClient.dio.get('/api/v1/dreams/$id');
      if (response.statusCode == 200) {
        return DreamModel.fromJson(response.data);
      }
    } catch (e) {
      print('API获取详情失败: $e');
    }
    
    // 本地查找
    final dreams = await LocalDreamStorage.getDreams();
    try {
      return dreams.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 创建新梦境（本地保存 + 尝试API）
  Future<DreamModel> createDream({
    required String content,
    required List<String> emotions,
    required List<String> scenes,
    required String date,
  }) async {
    final dream = DreamModel(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      createdAt: DateTime.now(),
      emotions: emotions,
      scenes: scenes,
      date: date,
    );

    // 先保存到本地（保证不丢失）
    await LocalDreamStorage.saveDream(dream);

    // 尝试API保存
    try {
      final response = await _dioClient.dio.post(
        '/api/v1/dreams',
        data: {
          'content': content,
          'emotion_tags': emotions,
          'scene_tags': scenes,
          'dream_date': date,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        // API保存成功，用服务器数据替换本地
        final serverDream = DreamModel.fromJson(response.data);
        await LocalDreamStorage.deleteDream(dream.id);
        await LocalDreamStorage.saveDream(serverDream);
        return serverDream;
      }
    } catch (e) {
      print('API保存失败，已保存到本地: $e');
      // API失败也没关系，本地已保存
    }

    return dream;
  }

  /// AI解析梦境
  Future<String> interpretDream(String dreamId) async {
    final dreams = await LocalDreamStorage.getDreams();
    DreamModel? dream;
    try {
      dream = dreams.firstWhere((d) => d.id == dreamId);
    } catch (e) {
      dream = null;
    }

    // 尝试API解析
    try {
      final response = await _dioClient.dio.post(
        '/api/v1/dreams/' + dreamId + '/interpretations',
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        // 兼容多种返回格式：markdown全文 / 结构化JSON
        String result = '';
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          final resultJson = responseData['result_json'];
          if (resultJson is Map<String, dynamic>) {
            // 新markdown格式
            result = resultJson['content'] ?? '';
            // 旧结构化格式拼接
            if (result.isEmpty && resultJson['summary'] != null) {
              final buffer = StringBuffer();
              buffer.writeln('## ' + (resultJson['summary'] ?? ''));
              if (resultJson['psychology_analysis'] != null) {
                buffer.writeln('\n### 心理学视角\n' + resultJson['psychology_analysis']);
              }
              if (resultJson['traditional_meaning'] != null) {
                buffer.writeln('\n### 传统解读\n' + resultJson['traditional_meaning']);
              }
              if (resultJson['reality_connection'] != null) {
                buffer.writeln('\n### 现实联结\n' + resultJson['reality_connection']);
              }
              final suggestions = resultJson['suggestions'] as List<dynamic>?;
              if (suggestions != null && suggestions.isNotEmpty) {
                buffer.writeln('\n### 行动建议\n');
                for (final s in suggestions) {
                  buffer.writeln('- ' + s.toString());
                }
              }
              result = buffer.toString();
            }
          } else if (resultJson is String) {
            result = resultJson;
          }
        }
        if (result.isNotEmpty) {
          if (dream != null) {
            final updated = DreamModel(
              id: dream.id,
              content: dream.content,
              createdAt: dream.createdAt,
              emotions: dream.emotions,
              scenes: dream.scenes,
              date: dream.date,
              interpretation: result.toString(),
            );
            await LocalDreamStorage.deleteDream(dream.id);
            await LocalDreamStorage.saveDream(updated);
          }
          return result.toString();
        }
      }
    } catch (e) {
      print('API解析失败，生成本地解析: ' + e.toString());
    }

    // API失败时生成本地基础解析
    final localResult = _generateLocalInterpretation(dream);
    if (dream != null) {
      final updated = DreamModel(
        id: dream.id,
        content: dream.content,
        createdAt: dream.createdAt,
        emotions: dream.emotions,
        scenes: dream.scenes,
        date: dream.date,
        interpretation: localResult,
      );
      await LocalDreamStorage.deleteDream(dream.id);
      await LocalDreamStorage.saveDream(updated);
    }
    return localResult;
  }

  /// 生成本地基础解析（API不可用时的后备）
  String _generateLocalInterpretation(DreamModel? dream) {
    if (dream == null) return '暂无法解析此梦境';

    final emotions = dream.emotions.isEmpty ? ['平静'] : dream.emotions;
    final scenes = dream.scenes.isEmpty ? ['日常生活'] : dream.scenes;

    final buffer = StringBuffer();
    buffer.writeln('## 梦境概览\n');
    buffer.writeln('你的梦境中出现了一些值得关注的元素。整体情绪基调偏向**' + emotions.join('、') + '**，主要场景包括' + scenes.join('、') + '。\n');
    buffer.writeln('## 情绪分析\n');
    buffer.writeln('从心理学角度看，梦中出现的**' + emotions.first + '**情绪往往反映了你近期潜意识的状态。弗洛伊德认为梦是"通往潜意识的皇家大道"，这种情绪的出现可能在提示你关注日常生活中被忽略的感受。\n');
    buffer.writeln('## 场景象征\n');
    for (final s in scenes) {
      buffer.writeln('- **' + s + '**：这是梦境中的重要符号，可能与你的现实处境存在潜在联结');
    }
    buffer.writeln('\n## 传统文化视角\n');
    buffer.writeln('《周公解梦》中，' + scenes.first + '相关的梦境多与人生阶段的转变有关。传统文化认为梦是内心与天地沟通的一种方式，不必过分紧张，也不宜完全忽视。\n');
    buffer.writeln('## 建议\n');
    buffer.writeln('1. **记录感受**：醒来后立即记录梦中的情绪，这些感受往往最真实');
    buffer.writeln('2. **联系现实**：思考近期生活中是否有与梦境呼应的事件');
    buffer.writeln('3. **保持觉察**：连续记录梦境有助于发现潜意识模式\n');
    buffer.writeln('---\n');
    buffer.writeln('*注：当前为离线基础解析。连接服务器后可获得更详细的AI深度解析（心理学+传统文化+现实联结三重视角）*');

    return buffer.toString();
  }
}
