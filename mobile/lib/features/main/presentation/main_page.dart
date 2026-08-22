import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 主页面 - 带底部导航
class MainPage extends StatefulWidget {
  final Widget child;

  const MainPage({super.key, required this.child});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const _routes = ['/', '/record', '/encyclopedia'];

  /// 根据当前路由获取导航索引
  int _getIndexFromLocation(String location) {
    if (location.startsWith('/record')) return 1;
    if (location.startsWith('/encyclopedia')) return 2;
    return 0;
  }

  void _onTap(int index) {
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    // 监听路由变化，同步导航栏高亮
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _getIndexFromLocation(location);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '我的梦',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_outlined),
            selectedIcon: Icon(Icons.edit),
            label: '记梦',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: '百科',
          ),
        ],
      ),
    );
  }
}
