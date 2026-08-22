import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dream_decode/features/auth/data/auth_storage.dart';
import 'package:dream_decode/features/dream/data/local_dream_storage.dart';
import 'package:dream_decode/core/env.dart';

/// 个人中心页面
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  int _dreamCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDreamCount();
  }

  Future<void> _loadDreamCount() async {
    final dreams = await LocalDreamStorage.getDreams();
    if (mounted) {
      setState(() => _dreamCount = dreams.length);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthStorage.clear();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 32),
          
          // 头像和用户信息
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.nightlight_round,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AuthStorage.isLoggedIn ? '已登录用户' : '未登录',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  Env.appName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 统计卡片
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('记录梦境', '$_dreamCount'),
                    _buildStatItem('连续打卡', '$_dreamCount'),
                    _buildStatItem('解析次数', '$_dreamCount'),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 功能列表
          _buildSection(
            '账户设置',
            [
              _buildListItem(
                icon: Icons.person_outline,
                title: '编辑资料',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('功能开发中...')),
                  );
                },
              ),
              _buildListItem(
                icon: Icons.lock_outline,
                title: '修改密码',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('功能开发中...')),
                  );
                },
              ),
            ],
          ),
          
          _buildSection(
            '通用设置',
            [
              _buildListItem(
                icon: Icons.notifications_outlined,
                title: '通知设置',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('功能开发中...')),
                  );
                },
              ),
              _buildListItem(
                icon: Icons.dark_mode_outlined,
                title: '深色模式',
                trailing: Switch(
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('功能开发中...')),
                    );
                  },
                ),
                onTap: null,
              ),
            ],
          ),
          
          _buildSection(
            '关于',
            [
              _buildListItem(
                icon: Icons.info_outline,
                title: '关于帽子解梦',
                subtitle: '版本 ${Env.appVersion}',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: '帽子解梦',
                    applicationVersion: Env.appVersion,
                    applicationLegalese: 'AI 解析结果仅供参考，不构成医疗或心理治疗建议',
                  );
                },
              ),
              _buildListItem(
                icon: Icons.privacy_tip_outlined,
                title: '隐私政策',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('功能开发中...')),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 退出登录按钮
          if (AuthStorage.isLoggedIn)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('退出登录'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
