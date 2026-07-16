import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../services/db_config_service.dart';
import '../../../services/leancloud_service.dart';

/// 登录页面 - 极简苹果风/玻璃拟态
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // 页面状态：checking → 检查邮箱中，login → 登录，register → 注册
  String _pageState = 'initial';
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _confirmEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = '请输入邮箱');
      return;
    }

    // WebDAV / Local 模式：跳过邮箱检查，直接进入密码输入
    final dbType = DbConfigService.currentDbType;
    if (dbType == DbType.webdav || dbType == DbType.local) {
      setState(() {
        _pageState = dbType == DbType.webdav ? 'login' : 'register';
        _error = null;
      });
      return;
    }

    if (!email.contains('@')) {
      setState(() => _error = '请输入有效的邮箱地址');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await LeanCloudService.checkEmailExists(email);

    setState(() {
      _isLoading = false;
      if (result == 'exists') {
        _pageState = 'login';
      } else if (result == 'not_found') {
        _pageState = 'register';
      } else {
        _error = '网络错误，请稍后再试';
      }
    });
  }

  // 开发者后台入口（通过正常 Supabase/WebDAV 账号登录后访问）

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success =
        await context.read<AuthProvider>().loginWithPassword(email, password);

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('欢迎回来 ✨'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else {
      setState(() {
        _error = context.read<AuthProvider>().error ?? '登录失败';
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final confirmEmail = _confirmEmailController.text.trim();
    final password = _passwordController.text;

    if (email != confirmEmail) {
      setState(() => _error = '两次输入的邮箱不一致');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success =
        await context.read<AuthProvider>().loginWithPassword(email, password);

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('注册成功 ✨'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else {
      setState(() {
        _error = context.read<AuthProvider>().error ?? '注册失败';
      });
    }
  }

  void _showForgotPasswordDialog() {
    final partnerEmailController = TextEditingController();
    String? dialogError;
    bool dialogLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.lock_reset_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('找回密码'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '请输入您伴侣的邮箱地址进行验证，验证通过后将发送密码重置邮件至您的邮箱。',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF8E8E93), height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: partnerEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: '伴侣的邮箱地址',
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 12),
                    Text(dialogError!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: dialogLoading
                      ? null
                      : () async {
                          setDialogState(() {
                            dialogLoading = true;
                            dialogError = null;
                          });

                          try {
                            final msg = await LeanCloudService
                                .resetPasswordWithPartnerEmail(
                              myEmail: _emailController.text.trim(),
                              partnerEmail: partnerEmailController.text.trim(),
                              newPassword: '', // 不使用，由邮件触发
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(msg),
                                    backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              dialogError =
                                  e.toString().replaceAll('Exception: ', '');
                            });
                          } finally {
                            setDialogState(() => dialogLoading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: dialogLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('验证'),
                ),
              ],
            );
          },
        );
      },
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // Logo
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: _BreathingLogo(color: theme.colorScheme.primary),
                  ),

                  const SizedBox(height: 20),
                  const Text('虫米',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: Color(0xFF1C1C1E))),
                  const SizedBox(height: 6),
                  const Text('记录恋爱的点点滴滴',
                      style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                          letterSpacing: 2)),
                  const SizedBox(height: 50),

                  // 表单卡片
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 10))
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 标题
                          Text(
                            _pageState == 'register' ? '注册新账号' : '登录',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1C1C1E)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _pageState == 'register'
                                ? '首次使用，请确认邮箱后注册。'
                                : _pageState == 'login'
                                    ? '请输入密码登录。'
                                    : '输入邮箱开始。',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF8E8E93)),
                          ),
                          const SizedBox(height: 20),

                          // 邮箱输入
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            enabled: _pageState == 'initial',
                            decoration: InputDecoration(
                              hintText: '邮箱地址',
                              prefixIcon: const Icon(Icons.email_outlined),
                              filled: true,
                              fillColor: _pageState == 'initial'
                                  ? const Color(0xFFF2F2F7)
                                  : Colors.grey.shade100,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty)
                                return '请输入邮箱';
                              if (!value.contains('@') || !value.contains('.'))
                                return '请输入有效的邮箱地址';
                              return null;
                            },
                          ),

                          // 注册时显示确认邮箱
                          if (_pageState == 'register') ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _confirmEmailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: '确认邮箱地址',
                                prefixIcon: const Icon(Icons.email_outlined),
                                filled: true,
                                fillColor: const Color(0xFFF2F2F7),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty)
                                  return '请再次输入邮箱';
                                if (value.trim() !=
                                    _emailController.text.trim())
                                  return '两次输入的邮箱不一致';
                                return null;
                              },
                            ),
                          ],

                          // 登录/注册时显示密码
                          if (_pageState == 'login' ||
                              _pageState == 'register') ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: '密码',
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                filled: true,
                                fillColor: const Color(0xFFF2F2F7),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return '请输入密码';
                                if (value.length < 6) return '密码长度不能少于 6 位';
                                return null;
                              },
                            ),
                          ],

                          const SizedBox(height: 24),

                          // 按钮
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      if (_pageState == 'initial') {
                                        _checkEmail();
                                      } else if (_pageState == 'login') {
                                        _handleLogin();
                                      } else {
                                        _handleRegister();
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white))
                                  : Text(
                                      _pageState == 'initial'
                                          ? '下一步'
                                          : _pageState == 'login'
                                              ? '登录'
                                              : '注册',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ),

                          // 返回按钮（登录/注册状态）
                          if (_pageState != 'initial') ...[
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _pageState = 'initial';
                                    _error = null;
                                    _passwordController.clear();
                                    _confirmEmailController.clear();
                                  });
                                },
                                child: const Text('返回',
                                    style: TextStyle(color: Color(0xFF8E8E93))),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 错误提示
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBF0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: Colors.redAccent, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),

                  // 找回密码入口（登录状态 + 密码错误时显示）
                  if (_pageState == 'login' &&
                      _error != null &&
                      _error!.contains('密码')) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        onPressed: _showForgotPasswordDialog,
                        icon: const Icon(Icons.help_outline_rounded, size: 16),
                        label: const Text('忘记密码？通过伴侣验证找回'),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.orange.shade700),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                  const Text(
                    '登录即表示同意《用户协议》与《隐私权政策》\n所有数据均妥善存储于情侣专属加密空间中。',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFFC7C7CC), height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // 数据库配置按钮
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
                        offset: const Offset(0, 2))
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

  void _showDatabaseConfigDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DatabaseConfigBottomSheet(),
    );
  }
}

/// 持续呼吸脉冲 Logo
class _BreathingLogo extends StatefulWidget {
  final Color color;
  const _BreathingLogo({required this.color});

  @override
  State<_BreathingLogo> createState() => _BreathingLogoState();
}

class _BreathingLogoState extends State<_BreathingLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.2, end: 0.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color.withValues(alpha: 0.85),
                  widget.color,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: _glow.value),
                  blurRadius: 20,
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
        );
      },
    );
  }
}

/// 数据库配置底部抽屉
class DatabaseConfigBottomSheet extends StatefulWidget {
  const DatabaseConfigBottomSheet({super.key});

  @override
  State<DatabaseConfigBottomSheet> createState() =>
      _DatabaseConfigBottomSheetState();
}

class _DatabaseConfigBottomSheetState extends State<DatabaseConfigBottomSheet> {
  static const List<DbType> _availableDbTypes = [DbType.webdav, DbType.local];

  late DbType _selectedType;

  // Supabase
  final _supaUrlController = TextEditingController();
  final _supaKeyController = TextEditingController();

  // WebDAV（坚果云地址已内置）
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
        url: DbConfigService.defaultWebdavUrl,
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

    // 本地模式免密登录
    await context
        .read<AuthProvider>()
        .loginWithPassword('local@love.app', 'loveapp2024');
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
        return 'LeanCloud / TDS 数据库';
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
            children: _availableDbTypes.map((type) {
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
                selectedColor:
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                checkmarkColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : const Color(0xFF1C1C1E),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: const Color(0xFFF2F2F7),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // 动态输入框
          if (_selectedType == DbType.supabase) ...[
            const Text('Supabase 连接参数',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
            // 坚果云地址内置，无需用户填写
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_done_rounded,
                      size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '坚果云 WebDAV · Cloudflare 代理',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _webdavUserController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: '坚果云账号 (电子邮箱)',
                hintText: 'your@email.com',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _webdavPwdController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '应用授权密码',
                hintText: '在坚果云安全设置中生成',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '双方使用同一坚果云账号登录即可自动同步。应用密码非坚果云登录密码，请在坚果云网页版 → 安全设置 → 第三方应用管理 中生成。',
              style: TextStyle(
                  fontSize: 11, color: Color(0xFF8E8E93), height: 1.4),
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
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '所有数据（日记、心愿、纪念日、生理期、亲密记）将完全存储于当前手机的本地数据库中，无需任何云端连接，数据私密安全。',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF8E8E93), height: 1.4),
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
            const Text('LeanCloud / TDS 参数',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _handleSave,
                child: const Text('保存并应用配置',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}
