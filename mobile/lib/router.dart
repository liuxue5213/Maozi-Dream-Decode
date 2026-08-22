import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/data/auth_storage.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/dream/presentation/dream_list_page.dart';
import 'features/dream/presentation/dream_record_page.dart';
import 'features/dream/presentation/interpretation_page.dart';
import 'features/encyclopedia/presentation/encyclopedia_page.dart';
import 'features/main/presentation/main_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = AuthStorage.isLoggedIn;
      final isLoginRoute = state.matchedLocation == '/login';
      
      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/';
      return null;
    },
    routes: [
      // 登录页（独立，无底部导航）
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      
      // 解析详情页（独立，无底部导航）
      GoRoute(
        path: '/interpretation/:id',
        builder: (context, state) => InterpretationPage(
          dreamId: int.parse(state.pathParameters['id']!),
        ),
      ),
      
      // 主导航页面（带底部导航）
      ShellRoute(
        builder: (context, state, child) => MainPage(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const DreamListPage()),
          GoRoute(path: '/record', builder: (context, state) => const DreamRecordPage()),
          GoRoute(path: '/encyclopedia', builder: (context, state) => const EncyclopediaPage()),
        ],
      ),
    ],
  );
});
