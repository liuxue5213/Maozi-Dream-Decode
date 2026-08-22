// 百科仓库 - 连接真实的API
import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import 'encyclopedia_model.dart';

class EncyclopediaRepository {
  final DioClient _dioClient = DioClient();

  /// 获取百科词条列表
  Future<List<EncyclopediaModel>> fetchEncyclopedia({
    String? keyword,
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (category != null && category != '全部') {
        queryParams['category'] = category;
      }

      final response = await _dioClient.dio.get(
        '/api/v1/encyclopedia',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => EncyclopediaModel.fromJson(item)).toList();
      }
      return <EncyclopediaModel>[];
    } catch (e) {
      print('获取百科列表失败: $e');
      return <EncyclopediaModel>[];
    }
  }

  /// 获取百科分类列表
  Future<List<String>> fetchCategories() async {
    try {
      final response = await _dioClient.dio.get('/api/v1/encyclopedia/categories');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
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
      final response = await _dioClient.dio.get('/api/v1/encyclopedia/$id');
      
      if (response.statusCode == 200) {
        return EncyclopediaModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('获取百科详情失败: $e');
      return null;
    }
  }
}
