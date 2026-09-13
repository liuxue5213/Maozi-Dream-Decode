// 梦境仓库 - API优先，本地存储后备
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dream_decode/core/network/dio_client.dart';
import 'dream_model.dart';
import 'local_dream_storage.dart';

class DreamRepository {
  final DioClient _dioClient = DioClient();

  /// 获取所有梦境列表（API优先，本地后备）
  Future<List<DreamModel>> fetchDreams() async {
    try {
      final response = await _dioClient.dio.get(
        'dreams',
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

  /// 获取梦境详情（本地优先，服务器兜底）
  Future<DreamModel?> getDreamDetail(String id) async {
    // 先查本地
    final localDreams = await LocalDreamStorage.getDreams();
    try {
      return localDreams.firstWhere((d) => d.id == id);
    } catch (_) {}

    // 提取服务器数字ID：srv_10 -> 10；local_xxx 无法查询服务器
    final numericId = int.tryParse(id.replaceFirst('srv_', ''));
    if (numericId == null) return null;

    try {
      final response = await _dioClient.dio.get('dreams/' + numericId.toString());
      if (response.statusCode == 200) {
        final dream = DreamModel.fromJson(response.data);
        final interpretation = await getLatestInterpretation(numericId.toString());
        if (interpretation == null) return dream;
        final updated = DreamModel(
          id: dream.id,
          content: dream.content,
          createdAt: dream.createdAt,
          emotions: dream.emotions,
          scenes: dream.scenes,
          date: dream.date,
          interpretation: interpretation,
          hasInterpretation: true,
        );
        await LocalDreamStorage.saveDream(updated);
        return updated;
      }
    } catch (e) {
      print('API获取详情失败: $e');
    }
    
    return null;
  }

  /// 创建新梦境（本地保存 + 尝试API）
  Future<DreamModel> createDream({
    required String content,
    required List<String> emotions,
    required List<String> scenes,
    required String date,
    int? sleepQuality,
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
        'dreams',
        data: {
          'content': content,
          'emotion_tags': emotions,
          'scene_tags': scenes,
          'dream_date': date,
          if (sleepQuality != null) 'sleep_quality': sleepQuality,
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
    if (dream != null && dream.interpretation != null && dream.interpretation!.isNotEmpty) {
      return dream.interpretation!; // 已有解析直接返回
    }

    // 服务器数字ID（srv_ 前缀）
    final serverNumericId = int.tryParse(dreamId.replaceFirst('srv_', ''));
    if (serverNumericId == null) {
      throw Exception('当前梦境未同步到服务器，无法调用 AI 解析');
    }

    // 尝试API解析
    try {
      final response = await _dioClient.dio.post(
        'dreams/' + serverNumericId.toString() + '/interpretations',
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
              hasInterpretation: true,
            );
            await LocalDreamStorage.deleteDream(dream.id);
            await LocalDreamStorage.saveDream(updated);
          }
          return result.toString();
        }
      }
    } catch (e) {
      print('API解析失败: ' + e.toString());
      throw Exception('AI 解析暂时不可用，请检查网络后重试');
    }

    throw Exception('AI 解析暂时不可用，请检查网络后重试');
  }

  /// 流式 AI 解析（打字机效果）：逐段返回增量文本
  Stream<String> interpretDreamStream(String dreamId) async* {
    final serverNumericId = int.tryParse(dreamId.replaceFirst('srv_', ''));
    if (serverNumericId == null) {
      throw Exception('当前梦境未同步到服务器，无法调用 AI 解析');
    }

    final response = await _dioClient.dio.post(
      'dreams/$serverNumericId/interpretations/stream',
      options: Options(
        responseType: ResponseType.stream,
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );

    final lines = response.data.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in lines) {
      if (!line.startsWith('data: ')) continue;
      final payload = line.substring(6).trim();
      if (payload.isEmpty) continue;
      final Map<String, dynamic> chunk;
      try {
        chunk = jsonDecode(payload) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      if (chunk['error'] != null) {
        throw Exception(chunk['error'].toString());
      }
      if (chunk['done'] == true) break;
      final text = chunk['content']?.toString() ?? '';
      if (text.isNotEmpty) yield text;
    }
  }

  /// 把解析结果写入本地缓存
  Future<void> saveInterpretation(String dreamId, String text) async {
    final dreams = await LocalDreamStorage.getDreams();
    DreamModel? dream;
    try {
      dream = dreams.firstWhere((d) => d.id == dreamId);
    } catch (_) {
      return;
    }
    final updated = DreamModel(
      id: dream.id,
      content: dream.content,
      createdAt: dream.createdAt,
      emotions: dream.emotions,
      scenes: dream.scenes,
      date: dream.date,
      interpretation: text,
      hasInterpretation: true,
    );
    await LocalDreamStorage.deleteDream(dream.id);
    await LocalDreamStorage.saveDream(updated);
  }

  Future<String?> getLatestInterpretation(String dreamId) async {
    try {
      final response = await _dioClient.dio.get('dreams/$dreamId/interpretations');
      final data = response.data as List<dynamic>;
      if (data.isEmpty) return null;
      final result = (data.first as Map<String, dynamic>)['result_json'];
      if (result is String) return result;
      if (result is Map<String, dynamic>) {
        return result['content']?.toString() ?? _formatStructuredInterpretation(result);
      }
    } catch (e) {
      print('API获取解析结果失败: $e');
    }
    return null;
  }

  String _formatStructuredInterpretation(Map<String, dynamic> result) {
    final buffer = StringBuffer();
    if (result['summary'] != null) buffer.writeln('## ${result['summary']}');
    if (result['psychology_analysis'] != null) {
      buffer.writeln('\n### 心理学视角\n${result['psychology_analysis']}');
    }
    if (result['traditional_meaning'] != null) {
      buffer.writeln('\n### 传统文化解读\n${result['traditional_meaning']}');
    }
    if (result['reality_connection'] != null) {
      buffer.writeln('\n### 现实联结\n${result['reality_connection']}');
    }
    final suggestions = result['suggestions'] as List<dynamic>?;
    if (suggestions != null && suggestions.isNotEmpty) {
      buffer.writeln('\n### 行动建议');
      for (final item in suggestions) {
        buffer.writeln('- $item');
      }
    }
    return buffer.toString();
  }

  /// 删除梦境（本地 + 尝试API）
  Future<void> deleteDream(String id) async {
    // 先删本地（保证删除成功）
    await LocalDreamStorage.deleteDream(id);

    // 尝试删除服务器数据（仅当存在数字ID时调用API）
    final delNumericId = int.tryParse(id.replaceFirst('srv_', ''));
    if (delNumericId != null) {
      try {
        await _dioClient.dio.delete(
          'dreams/' + delNumericId.toString(),
          options: Options(
            sendTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );
      } catch (e) {
        print('API删除失败（本地已删除）: ' + e.toString());
      }
    }
  }
}
