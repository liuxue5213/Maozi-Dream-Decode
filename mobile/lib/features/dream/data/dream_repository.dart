// 梦境仓库 - 连接真实的API
import 'package:maozi_dream_decode/lib/core/env.dart';

class DreamRepository {
  final DioClient _dioClient = DioClient();

  /// 获取所有梦境列表
  Future<List<Map<String, dynamic>>> fetchDreams() async {
    try {
      final response = await _dioClient.get('/api/v1/dreams');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.data);
        return data.map((item) => {
          return {
            'id': item['id'].toString(),
            'content': item['content'],
            'createdAt': item['createdAt'],
            'emotions': List<String>.from(item['emotions'] ?? []),
            'scenes': List<String>.from(item['scenes'] ?? []),
            'date': item['date'],
            'interpretation': item['interpretation'],
            'userId': item['userId'],
          };
        } as Map<String, dynamic>;
      }
      
      return [];
    } catch (e) {
      print('获取梦境列表失败: $e');
      return [];
    }
  }
  }

  /// 获取梦境详情
  Future<Map<String, dynamic>> getDreamDetail(String id) async {
    try {
      final response = await _dioClient.get('/api/v1/dreams/$id');
      
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      
      return <String, dynamic>{};
    } catch (e) {
      print('获取梦境详情失败: $e');
      return <String, dynamic>{};
    }
  }

  /// 创建新梦境
  Future<Map<String, dynamic>> createDream({
    required String content,
    required List<String> emotions,
    required List<String> scenes,
    required String date,
  }) async {
    try {
      final response = await _dioClient.post(
        '/api/v1/dreams',
        data: {
          'content': content,
          'emotions': emotions,
          'scenes': scenes,
          'date': date,
        },
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Env.apiToken}',
        },
      );
      
      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(response.data);
      }
      
      throw Exception('创建梦境失败');
    } catch (e) {
      print('创建梦境失败: $e');
      throw Exception('创建梦境失败');
    }
  }
}
