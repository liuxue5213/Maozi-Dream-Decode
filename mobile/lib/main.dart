import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/env.dart';
import 'features/auth/data/auth_storage.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Env.init();
  await AuthStorage.init();
  
  runApp(const ProviderScope(child: DreamApp()));
}

class DreamApp extends ConsumerWidget {
  const DreamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: Env.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B5B95),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      // 强制使用浅色主题，不跟随系统深色模式
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
