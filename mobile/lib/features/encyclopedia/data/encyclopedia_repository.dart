// 百科仓库 - API优先，本地数据后备
import 'package:dio/dio.dart';
import 'package:dream_decode/core/network/dio_client.dart';
import 'encyclopedia_model.dart';
import 'local_encyclopedia_data.dart';

class EncyclopediaRepository {
  final DioClient _dioClient = DioClient();

  /// 获取百科词条列表（API优先，本地后备）
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

      final endpoint = keyword != null && keyword.isNotEmpty
          ? 'encyclopedia/search'
          : 'encyclopedia';
      final response = await _dioClient.dio.get(
        endpoint,
        queryParameters: queryParams,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data is Map<String, dynamic>
            ? response.data['items'] as List<dynamic>? ?? []
            : response.data as List<dynamic>;
        if (data.isNotEmpty) {
          return data.map((item) => EncyclopediaModel.fromJson(item)).toList();
        }
      }
    } catch (e) {
      print('API获取百科失败，使用本地数据: $e');
    }
    
    // API失败或无数据，返回本地数据
    return _filterLocalData(keyword, category);
  }

  /// 过滤本地数据
  List<EncyclopediaModel> _filterLocalData(String? keyword, String? category) {
    var items = LocalEncyclopediaData.getAllItems();
    
    if (category != null && category != '全部') {
      items = items.where((item) => item.category == category).toList();
    }
    
    if (keyword != null && keyword.isNotEmpty) {
      items = items.where((item) => 
        item.title.contains(keyword) || item.brief.contains(keyword)
      ).toList();
    }
    
    return items;
  }

  /// 获取百科分类列表
  Future<List<String>> fetchCategories() async {
    try {
      final response = await _dioClient.dio.get(
        'encyclopedia/categories',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        if (data.isNotEmpty) {
          final categories = data
              .map((e) => (e as Map<String, dynamic>)['category'].toString())
              .toList();
          return ['全部', ...categories];
        }
      }
    } catch (e) {
      print('API获取分类失败，使用本地数据: $e');
    }
    
    return LocalEncyclopediaData.getCategories();
  }

  /// 获取百科词条详情
  Future<EncyclopediaModel?> getEncyclopediaDetail(String id) async {
    try {
      final response = await _dioClient.dio.get('encyclopedia/$id');
      if (response.statusCode == 200) {
        return EncyclopediaModel.fromJson(response.data);
      }
    } catch (e) {
      print('API获取详情失败: $e');
    }
    
    // 本地查找
    final items = LocalEncyclopediaData.getAllItems();
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }
}
