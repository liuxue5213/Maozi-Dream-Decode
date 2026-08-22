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
}
