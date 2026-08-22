// 百科仓库 - 连接真实的API
import 'dart:convert';
import '../data/encyclopedia_model.dart';
import '../../core/network/dio_client.dart';

class EncyclopediaRepository {
  final DioClient _dioClient = DioClient();

  /// 获取百科词条列表
  Future<List<EncyclopediaModel>> fetchEncyclopedia({
    String? keyword,
    String? category,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (category != null && category != '全部') {
        queryParams['category'] = category;
      }

      final response = await _dioClient.get(
        '/api/v1/encyclopedia',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is String 
            ? jsonDecode(response.data) 
            : response.data;
        return data.map((json) => EncyclopediaModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('获取百科列表失败: $e');
      return [];
    }
  }

  /// 获取百科分类列表
  Future<List<String>> fetchCategories() async {
    try {
      final response = await _dioClient.get('/api/v1/encyclopedia/categories');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is String 
            ? jsonDecode(response.data) 
            : response.data;
        return data.map((e) => e.toString()).toList();
      }
      return ['全部', '动物', '自然', '身体', '场景', '事件', '颜色'];
    } catch (e) {
      print('获取分类列表失败: $e');
      return ['全部', '动物', '自然', '身体', '场景', '事件', '颜色'];
    }
  }

  /// 获取百科词条详情
  Future<EncyclopediaModel?> getEncyclopediaDetail(String id) async {
    try {
      final response = await _dioClient.get('/api/v1/encyclopedia/$id');
      
      if (response.statusCode == 200) {
        final data = response.data is String 
            ? jsonDecode(response.data) 
            : response.data;
        return EncyclopediaModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('获取百科详情失败: $e');
      return null;
    }
  }
}
