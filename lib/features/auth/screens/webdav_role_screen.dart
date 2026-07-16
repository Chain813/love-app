import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/router/routes.dart';
import '../providers/auth_provider.dart';
import '../../../services/leancloud_service.dart';
import '../../../services/webdav_service.dart';

class WebdavRoleScreen extends StatefulWidget {
  const WebdavRoleScreen({super.key});

  @override
  State<WebdavRoleScreen> createState() => _WebdavRoleScreenState();
}

class _WebdavRoleScreenState extends State<WebdavRoleScreen> {
  late Future<Map<String, bool>> _availabilityFuture;
  String? _error;
  String? _selectingRole;

  @override
  void initState() {
    super.initState();
    _availabilityFuture = LeanCloudService.getWebdavRoleAvailability();
  }

  Future<void> _selectRole(String role) async {
    setState(() {
      _selectingRole = role;
      _error = null;
    });

    final success = await context.read<AuthProvider>().selectWebdavRole(role);
    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.home);
      return;
    }

    setState(() {
      _selectingRole = null;
      _error = context.read<AuthProvider>().error ?? '身份选择失败';
      _availabilityFuture = LeanCloudService.getWebdavRoleAvailability();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('选择我的身份'),
        actions: [
          TextButton(
            onPressed: () => context.read<AuthProvider>().logout(),
            child: const Text('退出', style: TextStyle(color: Color(0xFF8E8E93))),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, bool>>(
        future: _availabilityFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final availability = snapshot.data ??
              {
                WebdavService.roleUser1: false,
                WebdavService.roleUser2: false,
              };
          final user1Available = availability[WebdavService.roleUser1] ?? false;
          final user2Available = availability[WebdavService.roleUser2] ?? false;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                '双方使用同一个坚果云账号同步。请在这台设备上选择你的固定身份，另一台设备选择另一个身份。',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              _RoleCard(
                title: '我是 A',
                subtitle: user1Available ? '可绑定到这台设备' : '已被另一台设备占用',
                icon: Icons.looks_one_rounded,
                available: user1Available,
                loading: _selectingRole == WebdavService.roleUser1,
                onTap: () => _selectRole(WebdavService.roleUser1),
              ),
              const SizedBox(height: 12),
              _RoleCard(
                title: '我是 B',
                subtitle: user2Available ? '可绑定到这台设备' : '已被另一台设备占用',
                icon: Icons.looks_two_rounded,
                available: user2Available,
                loading: _selectingRole == WebdavService.roleUser2,
                onTap: () => _selectRole(WebdavService.roleUser2),
              ),
              if (_error != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                '如果两个身份都被占用，但你需要重新绑定，请让管理员在后台清除云端配对关系后重新创建共享空间。',
                style: TextStyle(color: theme.hintColor, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.available,
    required this.loading,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool available;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = available ? theme.colorScheme.primary : Colors.grey;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: available && !loading ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  available ? Icons.chevron_right_rounded : Icons.lock_rounded,
                  color: color,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
