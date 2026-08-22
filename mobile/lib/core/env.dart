import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 环境配置 - API 地址从 .env 文件读取
/// .env 文件由 GitHub Action 构建时从 Secrets 注入，不会提交到仓库
class Env {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  static String get appName => dotenv.env['APP_NAME'] ?? '帽子解梦';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      // .env 文件不存在时使用默认值（本地开发或测试场景）
      dotenv.env['API_BASE_URL'] = 'http://localhost:8000';
      dotenv.env['APP_NAME'] = '帽子解梦';
      dotenv.env['APP_VERSION'] = '1.0.0';
    }
  }
}
