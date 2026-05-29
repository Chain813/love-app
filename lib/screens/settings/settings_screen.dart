import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/db_config_service.dart';
import '../../services/leancloud_service.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _getCurrentDbName() {
    switch (DbConfigService.currentDbType) {
      case DbType.supabase:
        return 'Supabase 数据库';
      case DbType.webdav:
        return '坚果云 / WebDAV 云同步';
      case DbType.local:
        return '纯本地离线单机';
      case DbType.leancloud:
        return 'LeanCloud / TDS 数据库';
    }
  }

  Future<void> _triggerManualSync(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('正在同步云端数据...', style: TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // 检查/同步配对关系
      await LeanCloudService.checkPairStatus();
      
      // 同步各个业务模块
      await LeanCloudService.fetchDiaries();
      await LeanCloudService.fetchWishes();
      await LeanCloudService.fetchAnniversaries();
      await LeanCloudService.fetchPeriodLogs();
      await LeanCloudService.fetchIntimacyLogs();

      if (mounted) {
        Navigator.pop(context); // 关闭加载框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('数据同步成功！✨'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 关闭加载框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('同步失败：$e ❌'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 主题切换
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('主题颜色', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Consumer<ThemeProvider>(builder: (ctx, tp, _) {
                return Wrap(spacing: 12, runSpacing: 12, children: AppThemeType.values.map((t) {
                  final isSelected = tp.currentTheme == t;
                  final color = AppTheme.primaryColors[t]!;
                  return GestureDetector(
                    onTap: () => tp.setTheme(t),
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(14),
                        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                        boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))] : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 22) : null,
                    ),
                  );
                }).toList());
              }),
            ]),
          ),
          const SizedBox(height: 16),

          // 数据库与云同步设置
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  leading: const Icon(Icons.dns_rounded, color: Colors.blueAccent),
                  title: const Text('数据同步引擎设置'),
                  subtitle: Text(_getCurrentDbName()),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const DatabaseConfigBottomSheet(),
                    );
                    setState(() {}); // 刷新页面显示的引擎名称
                  },
                ),
                if (DbConfigService.currentDbType != DbType.local) ...[
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    leading: const Icon(Icons.sync_rounded, color: Colors.green),
                    title: const Text('立即手动同步数据'),
                    subtitle: const Text('从云端获取最新数据并与本地合并'),
                    onTap: () => _triggerManualSync(context),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 退出登录
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('退出登录', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('退出登录'),
                    content: const Text('确定要退出登录吗？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
                      TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('确定', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          // 注销账号
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: const Icon(Icons.delete_forever_rounded, color: Color(0xFF8E8E93)),
              title: const Text('注销账号', style: TextStyle(color: Color(0xFF8E8E93))),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('注销账号'),
                    content: const Text('注销后所有数据将永久删除，不可恢复。确定要注销吗？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
                      TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('确定注销', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await context.read<AuthProvider>().deleteAccount();
                  if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                }
              },
            ),
          ),
          const SizedBox(height: 32),
          Center(child: Text('虫米 v1.0.0', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)))),
        ],
      ),
    );
  }
}

