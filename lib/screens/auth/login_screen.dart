import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/db_config_service.dart';

/// 登录页面 - 极简苹果风/玻璃拟态
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    final success = await context.read<AuthProvider>().loginWithPassword(username, password);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('欢迎回来，$username ✨'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  void _showDatabaseConfigDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DatabaseConfigBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // Logo 动画心形
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.8),
                            theme.colorScheme.primary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 应用名称
                  const Text(
                    '虫米',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 副标题
                  const Text(
                    '记录恋爱的点点滴滴',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 50),

                  // 登录卡片
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '开启专属空间',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '若账号不存在，系统将自动为您注册账号。',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 账号输入
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              hintText: '账号',
                              prefixIcon: const Icon(Icons.person_outline_rounded),
                              filled: true,
                              fillColor: const Color(0xFFF2F2F7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                  return '请输入账号';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 密码输入
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: '密码',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              filled: true,
                              fillColor: const Color(0xFFF2F2F7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入密码';
                              }
                              if (value.length < 6) {
                                return '密码长度不能少于 6 位';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // 登录按钮
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              return SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: authProvider.isLoading
                                      ? null
                                      : () => _handleLogin(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: authProvider.isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          '进入专属空间',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 错误提示
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if (authProvider.error != null) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBF0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authProvider.error!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  const SizedBox(height: 40),

                  // 底部条款
                  const Text(
                    '登录即表示同意《用户协议》与《隐私权政策》\n所有数据均妥善存储于情侣专属加密空间中。',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFC7C7CC),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.dns_rounded),
                  color: theme.colorScheme.primary,
                  tooltip: '配置数据库',
                  onPressed: () => _showDatabaseConfigDialog(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 数据库配置底部抽屉
class DatabaseConfigBottomSheet extends StatefulWidget {
  const DatabaseConfigBottomSheet({super.key});

  @override
  State<DatabaseConfigBottomSheet> createState() => _DatabaseConfigBottomSheetState();
}

class _DatabaseConfigBottomSheetState extends State<DatabaseConfigBottomSheet> {
  late DbType _selectedType;

  // Supabase
  final _supaUrlController = TextEditingController();
  final _supaKeyController = TextEditingController();

  // WebDAV
  final _webdavUrlController = TextEditingController();
  final _webdavUserController = TextEditingController();
  final _webdavPwdController = TextEditingController();

  // LeanCloud
  final _lcIdController = TextEditingController();
  final _lcKeyController = TextEditingController();
  final _lcUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedType = DbConfigService.currentDbType;

    _supaUrlController.text = DbConfigService.supabaseUrl;
    _supaKeyController.text = DbConfigService.supabaseAnonKey;

    _webdavUrlController.text = DbConfigService.webdavUrl;
    _webdavUserController.text = DbConfigService.webdavUser;
    _webdavPwdController.text = DbConfigService.webdavPassword;

    _lcIdController.text = DbConfigService.leanCloudAppId;
    _lcKeyController.text = DbConfigService.leanCloudAppKey;
    _lcUrlController.text = DbConfigService.leanCloudServerUrl;
  }

  @override
  void dispose() {
    _supaUrlController.dispose();
    _supaKeyController.dispose();
    _webdavUrlController.dispose();
    _webdavUserController.dispose();
    _webdavPwdController.dispose();
    _lcIdController.dispose();
    _lcKeyController.dispose();
    _lcUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    // 切换类型
    await DbConfigService.setDbType(_selectedType);

    // 根据选择保存详细配置
    if (_selectedType == DbType.supabase) {
      await DbConfigService.saveSupabaseConfig(
        url: _supaUrlController.text.trim(),
        anonKey: _supaKeyController.text.trim(),
      );
    } else if (_selectedType == DbType.webdav) {
      await DbConfigService.saveWebdavConfig(
        url: _webdavUrlController.text.trim(),
        user: _webdavUserController.text.trim(),
        password: _webdavPwdController.text.trim(),
      );
    } else if (_selectedType == DbType.leancloud) {
      await DbConfigService.saveLeanCloudConfig(
        appId: _lcIdController.text.trim(),
        appKey: _lcKeyController.text.trim(),
        serverUrl: _lcUrlController.text.trim(),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('存储配置已切换为：${_getDbTypeName(_selectedType)} ✨'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _handleQuickLocalLogin() async {
    // 强制切为本地模式
    await DbConfigService.setDbType(DbType.local);
    if (!mounted) return;

    // 关闭抽屉
    Navigator.pop(context);

    // 触发本地 guest 登录
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已选择纯本地离线模式，正在登录... 🍃'),
        duration: Duration(milliseconds: 800),
      ),
    );

    // 模拟本地自动登录
    await context.read<AuthProvider>().loginWithPassword('本地用户', '123456');
  }

  String _getDbTypeName(DbType type) {
    switch (type) {
      case DbType.supabase:
        return 'Supabase (推荐)';
      case DbType.webdav:
        return '坚果云 / WebDAV 同步';
      case DbType.local:
        return '纯本地离线单机';
      case DbType.leancloud:
        return 'LeanCloud / TDS';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '数据存储与云同步设置',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 选择器
          const Text(
            '选择存储数据库类型',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 8),

          // 引擎单选列表
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DbType.values.map((type) {
              final isSelected = _selectedType == type;
              return ChoiceChip(
                label: Text(_getDbTypeName(type)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedType = type;
                    });
                  }
                },
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                checkmarkColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? theme.colorScheme.primary : const Color(0xFF1C1C1E),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: const Color(0xFFF2F2F7),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // 动态输入框
          if (_selectedType == DbType.supabase) ...[
            const Text('Supabase 连接参数', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _supaUrlController,
              decoration: const InputDecoration(
                labelText: 'Project URL (项目地址)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _supaKeyController,
              decoration: const InputDecoration(
                labelText: 'Anon Key (公开密钥)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            const Text(
              '提示：Supabase 是非常出色的免实名制云数据库。请在您 Supabase 项目的 SQL Editor 中执行建表脚本。',
              style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
            ),
          ] else if (_selectedType == DbType.webdav) ...[
            const Text('WebDAV 同步参数 (如坚果云)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _webdavUrlController,
              decoration: const InputDecoration(
                labelText: 'WebDAV 服务器地址',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _webdavUserController,
              decoration: const InputDecoration(
                labelText: '账号 (电子邮箱)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _webdavPwdController,
              decoration: const InputDecoration(
                labelText: '应用授权密码',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            const Text(
              '提示：使用 WebDAV 双方登录相同账号即可自动进行数据去重合并同步，完全不依赖第三方数据库服务器。',
              style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
            ),
          ] else if (_selectedType == DbType.local) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🍃 纯本地离线单机模式说明',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '所有数据（日记、心愿、纪念日、生理期、亲密记）将完全存储于当前手机的本地数据库中，无需任何云端连接，数据私密安全。',
                    style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93), height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.offline_bolt_rounded, size: 18),
                      label: const Text('一键离线登录进入'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      onPressed: _handleQuickLocalLogin,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_selectedType == DbType.leancloud) ...[
            const Text('LeanCloud / TDS 参数', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _lcIdController,
              decoration: const InputDecoration(
                labelText: 'App ID',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lcKeyController,
              decoration: const InputDecoration(
                labelText: 'App Key',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lcUrlController,
              decoration: const InputDecoration(
                labelText: 'Server URL (网关地址)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],

          const SizedBox(height: 28),

          // 保存按钮
          if (_selectedType != DbType.local)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _handleSave,
                child: const Text('保存并应用配置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}

