// 梦境仓库 - 连接真实的API
import 'dart:convert';
import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/env.dart';

class DreamRepository {
  final DioClient _dioClient = DioClient();

  /// 获取所有梦境列表
  Future<List<DreamModel>> fetchDreams() async {
    try {
      final response = await _dioClient.dio.get('/api/v1/dreams');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => DreamModel.fromJson(item)).toList();
      }
      
      return <DreamModel>[];
    } catch (e) {
      print('获取梦境列表失败: $e');
      return <DreamModel>[];
    }
  }

  /// 获取梦境详情
  Future<DreamModel?> getDreamDetail(String id) async {
    try {
      final response = await _dioClient.dio.get('/api/v1/dreams/$id');
      
      if (response.statusCode == 200) {
        return DreamModel.fromJson(response.data);
      }
      
      return null;
    } catch (e) {
      print('获取梦境详情失败: $e');
      return null;
    }
  }

  /// 创建新梦境
  Future<DreamModel> createDream({
    required String content,
    required List<String> emotions,
    required List<String> scenes,
    required String date,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/v1/dreams',
        data: {
          'content': content,
          'emotions': emotions,
          'scenes': scenes,
          'date': date,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 201) {
        return DreamModel.fromJson(response.data);
      }
      
      throw Exception('创建梦境失败');
    } catch (e) {
      print('创建梦境失败: $e');
      throw Exception('创建梦境失败: $e');
    }
  }
}
