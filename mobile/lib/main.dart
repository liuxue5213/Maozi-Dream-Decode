import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/env.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/data/auth_storage.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Env.init();
  await AuthStorage.init();

  runApp(const ProviderScope(child: DreamApp()));
}

class DreamApp extends ConsumerStatefulWidget {
  const DreamApp({super.key});

  @override
  ConsumerState<DreamApp> createState() => _DreamAppState();
}

class _DreamAppState extends ConsumerState<DreamApp> {
  @override
  void initState() {
    super.initState();
    ref.read(themeModeProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

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
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B5B95),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
