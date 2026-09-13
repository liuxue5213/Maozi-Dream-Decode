import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../app_keys.dart';
import '../env.dart';
import '../../features/auth/data/auth_storage.dart';

/// 网络请求客户端 - 使用从 GitHub Secrets 注入的 API 地址
class DioClient {
  late final Dio dio;

  DioClient() {
    dio = Dio(BaseOptions(
      // Keep the trailing slash so relative endpoints resolve below /api/v1/.
      baseUrl: '${Env.apiBaseUrl}/api/v1/',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    // 请求拦截器 - 自动附加 Token
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = AuthStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // 登录/注册接口的 401 是密码错误，不属于会话过期
          final path = error.requestOptions.path;
          final isAuthRequest = path.contains('auth/login') || path.contains('auth/register');
          if (!isAuthRequest && AuthStorage.isLoggedIn) {
            AuthStorage.clear();
            rootNavigatorKey.currentContext?.go('/login');
          }
        }
        handler.next(error);
      },
    ));
  }
}
