import 'package:shared_preferences/shared_preferences.dart';

/// 本地 Token 存储
class AuthStorage {
  static const _keyToken = 'access_token';
  static const _keyUserId = 'user_id';
  static const _keyNickname = 'nickname';

  static String? _cachedToken;
  static String? _cachedNickname;

  /// 保存 Token（同时更新内存缓存）
  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  /// 保存用户昵称（登录/注册成功后调用）
  static Future<void> saveNickname(String nickname) async {
    _cachedNickname = nickname;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNickname, nickname);
  }

  /// 获取昵称（同步读取内存缓存）
  static String? getNickname() => _cachedNickname;

  /// 获取 Token（同步读取内存缓存）
  static String? getToken() {
    return _cachedToken;
  }

  /// 初始化 - 从本地存储加载 Token 到内存缓存
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_keyToken);
    _cachedNickname = prefs.getString(_keyNickname);
  }

  /// 清除 Token
  static Future<void> clear() async {
    _cachedToken = null;
    _cachedNickname = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyNickname);
  }

  /// 是否已登录
  static bool get isLoggedIn => _cachedToken != null && _cachedToken!.isNotEmpty;
}
