// 本地梦境存储 - API不可用时的后备方案
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dream_model.dart';

class LocalDreamStorage {
  static const _keyDreams = 'local_dreams';

  /// 保存梦境到本地
  static Future<void> saveDream(DreamModel dream) async {
    final prefs = await SharedPreferences.getInstance();
    final dreams = await getDreams();
    dreams.insert(0, dream);
    final jsonList = dreams.map((d) => jsonEncode(d.toJson())).toList();
    await prefs.setStringList(_keyDreams, jsonList);
  }

  /// 获取本地所有梦境
  static Future<List<DreamModel>> getDreams() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_keyDreams) ?? [];
    return jsonList
        .map((json) => DreamModel.fromJson(jsonDecode(json)))
        .toList();
  }

  /// 删除本地梦境
  static Future<void> deleteDream(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final dreams = await getDreams();
    dreams.removeWhere((d) => d.id == id);
    final jsonList = dreams.map((d) => jsonEncode(d.toJson())).toList();
    await prefs.setStringList(_keyDreams, jsonList);
  }
}
