import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/data/auth_storage.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/dream/presentation/dream_list_page.dart';
import 'features/dream/presentation/dream_record_page.dart';
import 'features/dream/presentation/dream_detail_page.dart';
import 'features/encyclopedia/presentation/encyclopedia_page.dart';
import 'features/main/presentation/main_page.dart';
import 'features/profile/presentation/profile_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // 游客模式：不再强制登录，但保留登录页入口
      final isLoginRoute = state.matchedLocation == '/login';
      final isLoggedIn = AuthStorage.isLoggedIn;

      // 已登录用户访问登录页则回首页；游客可直接浏览应用
      if (isLoggedIn && isLoginRoute) return '/';
      return null;
    },
    routes: [
      // 登录页（独立，无底部导航）
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      
      // 个人中心页（独立，无底部导航）
      GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
      
      // 梦境详情页（独立，无底部导航）
      GoRoute(
        path: '/dream/:id',
        builder: (context, state) => DreamDetailPage(
          dreamId: state.pathParameters['id']!,
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
