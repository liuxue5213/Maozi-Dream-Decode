import 'package:shared_preferences/shared_preferences.dart';

/// 本地 Token 存储
class AuthStorage {
  static const _keyToken = 'access_token';
  static const _keyUserId = 'user_id';

  static String? _cachedToken;

  /// 保存 Token（同时更新内存缓存）
  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  /// 获取 Token（同步读取内存缓存）
  static String? getToken() {
    return _cachedToken;
  }

  /// 初始化 - 从本地存储加载 Token 到内存缓存
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_keyToken);
  }

  /// 清除 Token
  static Future<void> clear() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
  }

  /// 是否已登录
  static bool get isLoggedIn => _cachedToken != null && _cachedToken!.isNotEmpty;
}
