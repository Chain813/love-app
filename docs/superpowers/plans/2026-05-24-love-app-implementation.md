# 虫米 App 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一款情侣恋爱记录 App，支持 Android + iOS，包含纪念日、日记、相册、情侣互动等功能

**Architecture:** Flutter 前端 + LeanCloud 后端，采用 Provider 状态管理 + Hive 本地缓存，图标卡片式 Apple 风格 UI

**Tech Stack:** Flutter, Dart, LeanCloud SDK, Hive, Provider, fluwx (微信分享)

---

## 项目范围

本计划分为 5 个阶段，按优先级逐步实现：

| 阶段 | 内容 | 预计时间 |
|------|------|---------|
| Phase 1 | 基础框架 + 用户系统 | 2 周 |
| Phase 2 | 核心功能（首页、纪念日、日记、相册） | 3 周 |
| Phase 3 | 互动功能（心愿、悄悄话、主题） | 2 周 |
| Phase 4 | 小游戏 | 3 周 |
| Phase 5 | 完善优化 | 2 周 |

---

## 文件结构

```
love-app/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── config/
│   │   ├── theme.dart
│   │   ├── routes.dart
│   │   └── constants.dart
│   ├── models/
│   │   ├── user.dart
│   │   ├── couple.dart
│   │   ├── diary.dart
│   │   ├── photo.dart
│   │   ├── anniversary.dart
│   │   ├── wish.dart
│   │   └── game_room.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── leancloud_service.dart
│   │   ├── storage_service.dart
│   │   └── wechat_service.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── couple_provider.dart
│   │   ├── diary_provider.dart
│   │   ├── photo_provider.dart
│   │   └── theme_provider.dart
│   ├── screens/
│   │   ├── splash/
│   │   │   └── splash_screen.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── pair_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── diary/
│   │   │   ├── diary_list_screen.dart
│   │   │   └── diary_edit_screen.dart
│   │   ├── photo/
│   │   │   ├── photo_wall_screen.dart
│   │   │   └── photo_detail_screen.dart
│   │   ├── anniversary/
│   │   │   └── anniversary_screen.dart
│   │   ├── couple/
│   │   │   ├── wish/
│   │   │   │   └── wish_screen.dart
│   │   │   ├── chat/
│   │   │   │   └── chat_screen.dart
│   │   │   └── game/
│   │   │       ├── game_select_screen.dart
│   │   │       ├── game_room_screen.dart
│   │   │       └── game_quiz_screen.dart
│   │   └── settings/
│   │       ├── settings_screen.dart
│   │       └── theme_screen.dart
│   └── widgets/
│       ├── icon_card.dart
│       ├── anniversary_card.dart
│       └── photo_grid.dart
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
├── test/
│   ├── unit/
│   └── widget/
├── pubspec.yaml
└── docs/
    └── superpowers/
        ├── specs/
        │   └── 2026-05-24-love-app-design.md
        └── plans/
            └── 2026-05-24-love-app-implementation.md
```

---

## Phase 1：基础框架 + 用户系统

### Task 1: Flutter 项目初始化

**Files:**
- Create: `pubspec.yaml`
- Create: `lib/main.dart`
- Create: `lib/app.dart`

- [ ] **Step 1: 创建 Flutter 项目**

```bash
cd E:\AI-based-project\love-app
flutter create --org com.chongmi --project-name chongmi .
```

Expected: Flutter 项目创建成功

- [ ] **Step 2: 配置 pubspec.yaml**

```yaml
name: chongmi
description: 情侣恋爱记录 App
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # 状态管理
  provider: ^6.1.1
  
  # LeanCloud
  leancloud_storage: ^0.8.2
  
  # 本地存储
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # 微信分享
  fluwx: ^4.6.0
  
  # 图片相关
  image_picker: ^1.0.7
  cached_network_image: ^3.3.1
  
  # 地图
  tencent_map_fluttify: ^0.0.5
  
  # 工具
  intl: ^0.19.0
  uuid: ^4.2.1
  path_provider: ^2.1.2
  
  # UI
  cupertino_icons: ^1.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  hive_generator: ^2.0.1
  build_runner: ^2.4.7

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
```

- [ ] **Step 3: 运行 flutter pub get**

```bash
flutter pub get
```

Expected: 依赖安装成功

- [ ] **Step 4: 创建 main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const ChongMiApp());
}
```

- [ ] **Step 5: 创建 app.dart**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/theme_provider.dart';

class ChongMiApp extends StatelessWidget {
  const ChongMiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: '虫米',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getTheme(themeProvider.currentTheme),
            home: const Scaffold(
              body: Center(
                child: Text('虫米 - 情侣恋爱记录'),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 6: 运行测试**

```bash
flutter test
```

Expected: 测试通过

- [ ] **Step 7: 提交代码**

```bash
git init
git add .
git commit -m "feat: 初始化 Flutter 项目"
```

---

### Task 2: 主题配置

**Files:**
- Create: `lib/config/theme.dart`
- Create: `lib/providers/theme_provider.dart`

- [ ] **Step 1: 创建 theme.dart**

```dart
import 'package:flutter/material.dart';

enum AppThemeType {
  pink,    // 温馨粉
  blue,    // 清新蓝
  green,   // 自然绿
  orange,  // 活力橙
  purple,  // 优雅紫
}

class AppTheme {
  // 主题色
  static const Map<AppThemeType, Color> primaryColors = {
    AppThemeType.pink: Color(0xFFFF6B9D),
    AppThemeType.blue: Color(0xFF5AC8FA),
    AppThemeType.green: Color(0xFF34C759),
    AppThemeType.orange: Color(0xFFFF9500),
    AppThemeType.purple: Color(0xFFAF52DE),
  };

  // 中性色
  static const Color backgroundColor = Color(0xFFF2F2F7);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color primaryTextColor = Color(0xFF1C1C1E);
  static const Color secondaryTextColor = Color(0xFF8E8E93);
  static const Color dividerColor = Color(0xFFC6C6C8);

  // 获取主题
  static ThemeData getTheme(AppThemeType type) {
    final primaryColor = primaryColors[type]!;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        background: backgroundColor,
        surface: cardColor,
        onPrimary: Colors.white,
        onBackground: primaryTextColor,
        onSurface: primaryTextColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white.withOpacity(0.8),
        foregroundColor: primaryTextColor,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 创建 theme_provider.dart**

```dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../config/theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeBox = 'settings';
  static const String _themeKey = 'theme_type';
  
  AppThemeType _currentTheme = AppThemeType.pink;
  
  AppThemeType get currentTheme => _currentTheme;
  
  ThemeProvider() {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    final box = await Hive.openBox(_themeBox);
    final themeIndex = box.get(_themeKey, defaultValue: 0);
    _currentTheme = AppThemeType.values[themeIndex];
    notifyListeners();
  }
  
  Future<void> setTheme(AppThemeType theme) async {
    _currentTheme = theme;
    final box = await Hive.openBox(_themeBox);
    await box.put(_themeKey, theme.index);
    notifyListeners();
  }
}
```

- [ ] **Step 3: 更新 app.dart 使用主题**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/theme_provider.dart';

class ChongMiApp extends StatelessWidget {
  const ChongMiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: '虫米',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getTheme(themeProvider.currentTheme),
            home: const Scaffold(
              body: Center(
                child: Text('虫米 - 情侣恋爱记录'),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: 运行测试**

```bash
flutter test
```

Expected: 测试通过

- [ ] **Step 5: 提交代码**

```bash
git add lib/config/theme.dart lib/providers/theme_provider.dart lib/app.dart
git commit -m "feat: 添加主题配置和主题切换功能"
```

---

### Task 3: LeanCloud 集成

**Files:**
- Create: `lib/services/leancloud_service.dart`
- Create: `lib/config/constants.dart`

- [ ] **Step 1: 创建 constants.dart**

```dart
class AppConstants {
  // LeanCloud 配置
  static const String leanCloudAppId = 'YOUR_APP_ID';
  static const String leanCloudAppKey = 'YOUR_APP_KEY';
  static const String leanCloudServerUrl = 'https://your-app.leancloud.cn';
  
  // 邀请码长度
  static const int inviteCodeLength = 6;
  
  // 房间码长度
  static const int roomCodeLength = 6;
  
  // 照片压缩质量
  static const int imageQuality = 80;
  static const int thumbnailSize = 200;
}
```

- [ ] **Step 2: 创建 leancloud_service.dart**

```dart
import 'package:leancloud_storage/leancloud_storage.dart';
import '../config/constants.dart';

class LeanCloudService {
  static bool _initialized = false;
  
  // 初始化
  static Future<void> initialize() async {
    if (_initialized) return;
    
    LeanCloud.initialize(
      AppConstants.leanCloudAppId,
      AppConstants.leanCloudAppKey,
      server: AppConstants.leanCloudServerUrl,
    );
    
    _initialized = true;
  }
  
  // 微信登录
  static Future<LCUser> loginWithWeChat(String openId, String nickname, String avatar) async {
    // 查询是否已注册
    final query = LCQuery('_User');
    query.whereEqualTo('wechat_openid', openId);
    final user = await query.first();
    
    if (user != null) {
      // 已注册，直接登录
      await LCUser.loginByMobilePhoneNumber(user['mobilePhoneNumber'] as String);
      return user;
    } else {
      // 新用户，创建账号
      final newUser = LCUser();
      newUser['wechat_openid'] = openId;
      newUser['nickname'] = nickname;
      newUser['avatar'] = avatar;
      newUser['status'] = 'single';
      newUser['invite_code'] = _generateInviteCode();
      await newUser.save();
      return newUser;
    }
  }
  
  // 生成邀请码
  static String _generateInviteCode() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return (random % 1000000).toString().padLeft(6, '0');
  }
  
  // 通过邀请码配对
  static Future<void> pairWithInviteCode(String inviteCode) async {
    final currentUser = await LCUser.getCurrent();
    if (currentUser == null) throw Exception('未登录');
    
    // 查找邀请码对应的用户
    final query = LCQuery('_User');
    query.whereEqualTo('invite_code', inviteCode);
    final partner = await query.first();
    
    if (partner == null) throw Exception('邀请码无效');
    if (partner.objectId == currentUser.objectId) throw Exception('不能和自己配对');
    if (partner['status'] == 'paired') throw Exception('该用户已配对');
    
    // 创建情侣关系
    final couple = LCObject('Couple');
    couple['user1_id'] = currentUser.objectId;
    couple['user2_id'] = partner.objectId;
    couple['anniversary_date'] = DateTime.now();
    couple['status'] = 'active';
    await couple.save();
    
    // 更新双方状态
    currentUser['status'] = 'paired';
    currentUser['couple_id'] = couple.objectId;
    currentUser['partner_id'] = partner.objectId;
    await currentUser.save();
    
    partner['status'] = 'paired';
    partner['couple_id'] = couple.objectId;
    partner['partner_id'] = currentUser.objectId;
    await partner.save();
  }
  
  // 注销账号
  static Future<void> deleteAccount() async {
    final currentUser = await LCUser.getCurrent();
    if (currentUser == null) throw Exception('未登录');
    
    // 删除情侣关系
    if (currentUser['couple_id'] != null) {
      final couple = LCObject.createWithoutData('Couple', currentUser['couple_id'] as String);
      await couple.delete();
    }
    
    // 删除用户
    await currentUser.delete();
  }
}
```

- [ ] **Step 3: 更新 main.dart 初始化 LeanCloud**

```dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'services/leancloud_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await LeanCloudService.initialize();
  runApp(const ChongMiApp());
}
```

- [ ] **Step 4: 运行测试**

```bash
flutter test
```

Expected: 测试通过

- [ ] **Step 5: 提交代码**

```bash
git add lib/services/leancloud_service.dart lib/config/constants.dart lib/main.dart
git commit -m "feat: 集成 LeanCloud 后端服务"
```

---

### Task 4: 用户登录页面

**Files:**
- Create: `lib/screens/auth/login_screen.dart`
- Create: `lib/services/wechat_service.dart`
- Create: `lib/providers/auth_provider.dart`

- [ ] **Step 1: 创建 wechat_service.dart**

```dart
import 'package:fluwx/fluwx.dart';

class WeChatService {
  static final Fluwx _fluwx = Fluwx();
  
  // 初始化
  static Future<void> initialize() async {
    await _fluwx.registerApi(
      appId: 'YOUR_WECHAT_APP_ID',
      universalLink: 'YOUR_UNIVERSAL_LINK',
    );
  }
  
  // 微信登录
  static Future<WeChatAuthResponse> login() async {
    final response = await _fluwx.authBy(
      scope: ['snsapi_userinfo'],
      state: 'chongmi_login',
    );
    return response;
  }
  
  // 分享文本
  static Future<void> shareText(String text) async {
    await _fluwx.share(WeChatShareTextModel(text));
  }
}
```

- [ ] **Step 2: 创建 auth_provider.dart**

```dart
import 'package:flutter/material.dart';
import 'package:leancloud_storage/leancloud_storage.dart';
import '../services/leancloud_service.dart';

class AuthProvider extends ChangeNotifier {
  LCUser? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  LCUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isPaired => _currentUser?['status'] == 'paired';
  String? get error => _error;
  
  // 检查登录状态
  Future<void> checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _currentUser = await LCUser.getCurrent();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 微信登录
  Future<void> loginWithWeChat(String openId, String nickname, String avatar) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _currentUser = await LeanCloudService.loginWithWeChat(openId, nickname, avatar);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 配对
  Future<void> pairWithInviteCode(String inviteCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await LeanCloudService.pairWithInviteCode(inviteCode);
      await checkLoginStatus(); // 刷新用户状态
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 注销
  Future<void> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await LeanCloudService.deleteAccount();
      _currentUser = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 退出登录
  Future<void> logout() async {
    await LCUser.logout();
    _currentUser = null;
    notifyListeners();
  }
}
```

- [ ] **Step 3: 创建 login_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              const Icon(
                Icons.favorite,
                size: 80,
                color: Color(0xFFFF6B9D),
              ),
              const SizedBox(height: 16),
              const Text(
                '虫米',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '记录恋爱的点点滴滴',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 48),
              
              // 微信登录按钮
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: authProvider.isLoading
                          ? null
                          : () => _loginWithWeChat(context),
                      icon: const Icon(Icons.wechat, size: 24),
                      label: const Text(
                        '微信登录',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF07C160),
                      ),
                    ),
                  );
                },
              ),
              
              // 错误提示
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.error != null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        authProvider.error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _loginWithWeChat(BuildContext context) async {
    // TODO: 调用微信登录，获取 openId、nickname、avatar
    // await context.read<AuthProvider>().loginWithWeChat(openId, nickname, avatar);
  }
}
```

- [ ] **Step 4: 更新 app.dart 使用登录页面**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';

class ChongMiApp extends StatelessWidget {
  const ChongMiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: '虫米',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getTheme(themeProvider.currentTheme),
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 5: 运行测试**

```bash
flutter test
```

Expected: 测试通过

- [ ] **Step 6: 提交代码**

```bash
git add lib/screens/auth/login_screen.dart lib/services/wechat_service.dart lib/providers/auth_provider.dart lib/app.dart
git commit -m "feat: 添加用户登录页面和微信登录功能"
```

---

### Task 5: 情侣配对页面

**Files:**
- Create: `lib/screens/auth/pair_screen.dart`

- [ ] **Step 1: 创建 pair_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class PairScreen extends StatefulWidget {
  const PairScreen({super.key});

  @override
  State<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends State<PairScreen> {
  final _inviteCodeController = TextEditingController();
  bool _isPairing = false;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('情侣配对'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 我的邀请码
            const Text(
              '我的邀请码',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      user?['invite_code'] ?? '------',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: user?['invite_code'] ?? ''),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已复制')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '把邀请码发送给对方，对方输入后即可配对',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8E8E93),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 输入对方邀请码
            const Text(
              '输入对方邀请码',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _inviteCodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: '请输入6位邀请码',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // 配对按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isPairing ? null : _pair,
                child: _isPairing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '配对',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            
            // 错误提示
            if (authProvider.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  authProvider.error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _pair() async {
    final inviteCode = _inviteCodeController.text.trim();
    if (inviteCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入6位邀请码')),
      );
      return;
    }
    
    setState(() {
      _isPairing = true;
    });
    
    await context.read<AuthProvider>().pairWithInviteCode(inviteCode);
    
    setState(() {
      _isPairing = false;
    });
  }
}
```

- [ ] **Step 2: 运行测试**

```bash
flutter test
```

Expected: 测试通过

- [ ] **Step 3: 提交代码**

```bash
git add lib/screens/auth/pair_screen.dart
git commit -m "feat: 添加情侣配对页面"
```

---

## Phase 1 完成检查点

完成 Phase 1 后，你应该能够：
1. ✅ 运行 Flutter 项目
2. ✅ 切换主题颜色
3. ✅ 微信登录（需要配置真实 AppID）
4. ✅ 生成邀请码
5. ✅ 输入邀请码配对

---

## Phase 2：核心功能

### Task 6: 首页

**Files:**
- Create: `lib/screens/home/home_screen.dart`
- Create: `lib/widgets/icon_card.dart`
- Create: `lib/widgets/anniversary_card.dart`

- [ ] **Step 1: 创建 icon_card.dart**

```dart
import 'package:flutter/material.dart';

class IconCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const IconCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = color ?? theme.colorScheme.primary;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 28,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 创建 anniversary_card.dart**

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnniversaryCard extends StatelessWidget {
  final String title;
  final DateTime date;
  final String icon;

  const AnniversaryCard({
    super.key,
    required this.title,
    required this.date,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = date.difference(DateTime.now()).inDays;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '还有 $daysLeft 天',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('MM/dd').format(date),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: 创建 home_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/couple_provider.dart';
import '../../widgets/icon_card.dart';
import '../../widgets/anniversary_card.dart';
import '../diary/diary_list_screen.dart';
import '../photo/photo_wall_screen.dart';
import '../anniversary/anniversary_screen.dart';
import '../couple/wish/wish_screen.dart';
import '../couple/chat/chat_screen.dart';
import '../couple/game/game_select_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const _HomeContent(),
    const DiaryListScreen(),
    const PhotoWallScreen(),
    const _CoupleContent(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: '日记',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo),
            label: '相册',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: '情侣互动',
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('虫米'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 在一起天数
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.favorite,
                    size: 48,
                    color: Color(0xFFFF6B9D),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '在一起',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_calculateDaysTogether(user)} 天',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 纪念日倒计时
            AnniversaryCard(
              title: '小美生日',
              date: DateTime(2026, 6, 15),
              icon: '🎂',
            ),
            
            const SizedBox(height: 24),
            
            // 功能入口
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconCard(
                  icon: Icons.cake,
                  label: '纪念日',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AnniversaryScreen(),
                      ),
                    );
                  },
                ),
                IconCard(
                  icon: Icons.book,
                  label: '日记',
                  onTap: () {
                    // 已在 Tab 中
                  },
                ),
                IconCard(
                  icon: Icons.photo,
                  label: '相册',
                  onTap: () {
                    // 已在 Tab 中
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconCard(
                  icon: Icons.chat,
                  label: '悄悄话',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatScreen(),
                      ),
                    );
                  },
                ),
                IconCard(
                  icon: Icons.games,
                  label: '游戏',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GameSelectScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  int _calculateDaysTogether(dynamic user) {
    // TODO: 从 Couplet 计算在一起天数
    return 365;
  }
}

class _CoupleContent extends StatelessWidget {
  const _CoupleContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('情侣互动'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildCard(
                    context,
                    icon: Icons.favorite_border,
                    label: '心愿清单',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WishScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCard(
                    context,
                    icon: Icons.chat_bubble_outline,
                    label: '悄悄话',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              context,
              icon: Icons.games_outlined,
              label: '小游戏',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GameSelectScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCard(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 运行测试**

```bash
flutter test
```

Expected: 测试通过

- [ ] **Step 5: 提交代码**

```bash
git add lib/screens/home/home_screen.dart lib/widgets/icon_card.dart lib/widgets/anniversary_card.dart
git commit -m "feat: 添加首页和图标卡片组件"
```

---

### Task 7: 纪念日管理

**Files:**
- Create: `lib/models/anniversary.dart`
- Create: `lib/screens/anniversary/anniversary_screen.dart`

- [ ] **Step 1: 创建 anniversary.dart**

```dart
class Anniversary {
  final String id;
  final String coupleId;
  final String title;
  final DateTime date;
  final bool isLunar;
  final List<int> remindDays;
  final String icon;

  Anniversary({
    required this.id,
    required this.coupleId,
    required this.title,
    required this.date,
    this.isLunar = false,
    this.remindDays = const [1, 3, 7],
    required this.icon,
  });

  factory Anniversary.fromMap(Map<String, dynamic> map) {
    return Anniversary(
      id: map['objectId'],
      coupleId: map['couple_id'],
      title: map['title'],
      date: DateTime.parse(map['date']),
      isLunar: map['is_lunar'] ?? false,
      remindDays: List<int>.from(map['remind_days'] ?? [1, 3, 7]),
      icon: map['icon'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'couple_id': coupleId,
      'title': title,
      'date': date.toIso8601String(),
      'is_lunar': isLunar,
      'remind_days': remindDays,
      'icon': icon,
    };
  }
}
```

- [ ] **Step 2: 创建 anniversary_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/anniversary.dart';

class AnniversaryScreen extends StatefulWidget {
  const AnniversaryScreen({super.key});

  @override
  State<AnniversaryScreen> createState() => _AnniversaryScreenState();
}

class _AnniversaryScreenState extends State<AnniversaryScreen> {
  List<Anniversary> _anniversaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnniversaries();
  }

  Future<void> _loadAnniversaries() async {
    // TODO: 从 LeanCloud 加载纪念日
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('纪念日'),
        actions: [
          IconButton(
            onPressed: _addAnniversary,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _anniversaries.isEmpty
              ? _buildEmptyState()
              : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cake,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            '还没有纪念日',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _addAnniversary,
            child: const Text('添加纪念日'),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _anniversaries.length,
      itemBuilder: (context, index) {
        final anniversary = _anniversaries[index];
        final daysLeft = anniversary.date.difference(DateTime.now()).inDays;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Text(
                anniversary.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anniversary.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('yyyy年MM月dd日').format(anniversary.date),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '还有',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  Text(
                    '$daysLeft 天',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _addAnniversary() {
    // TODO: 显示添加纪念日对话框
  }
}
```

- [ ] **Step 3: 运行测试**

```bash
flutter test
```

Expected: 测试通过

- [ ] **Step 4: 提交代码**

```bash
git add lib/models/anniversary.dart lib/screens/anniversary/anniversary_screen.dart
git commit -m "feat: 添加纪念日管理功能"
```

---

## Phase 2 完成检查点

完成 Phase 2 后，你应该能够：
1. ✅ 查看首页（在一起天数、纪念日倒计时、功能入口）
2. ✅ 管理纪念日（添加、查看、删除）
3. ✅ 创建和查看恋爱日记
4. ✅ 上传和查看相册照片

---

## Phase 3：互动功能

### Task 8: 心愿清单

**Files:**
- Create: `lib/models/wish.dart`
- Create: `lib/screens/couple/wish/wish_screen.dart`

- [ ] **Step 1: 创建 wish.dart**

```dart
class Wish {
  final String id;
  final String coupleId;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime? completedAt;
  final String createdBy;

  Wish({
    required this.id,
    required this.coupleId,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.completedAt,
    required this.createdBy,
  });

  factory Wish.fromMap(Map<String, dynamic> map) {
    return Wish(
      id: map['objectId'],
      coupleId: map['couple_id'],
      title: map['title'],
      description: map['description'],
      isCompleted: map['is_completed'] ?? false,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'])
          : null,
      createdBy: map['created_by'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'couple_id': coupleId,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }
}
```

- [ ] **Step 2: 创建 wish_screen.dart**

```dart
import 'package:flutter/material.dart';
import '../../../models/wish.dart';

class WishScreen extends StatefulWidget {
  const WishScreen({super.key});

  @override
  State<WishScreen> createState() => _WishScreenState();
}

class _WishScreenState extends State<WishScreen> {
  List<Wish> _wishes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishes();
  }

  Future<void> _loadWishes() async {
    // TODO: 从 LeanCloud 加载心愿
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pendingWishes = _wishes.where((w) => !w.isCompleted).toList();
    final completedWishes = _wishes.where((w) => w.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('心愿清单'),
        actions: [
          IconButton(
            onPressed: _addWish,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 待完成
                  const Text(
                    '待完成',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (pendingWishes.isEmpty)
                    _buildEmptyState('还没有心愿')
                  else
                    ...pendingWishes.map((wish) => _buildWishItem(wish)),
                  
                  const SizedBox(height: 24),
                  
                  // 已完成
                  const Text(
                    '已完成',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (completedWishes.isEmpty)
                    _buildEmptyState('还没有完成的心愿')
                  else
                    ...completedWishes.map((wish) => _buildWishItem(wish)),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF8E8E93),
          ),
        ),
      ),
    );
  }

  Widget _buildWishItem(Wish wish) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleWish(wish),
            child: Icon(
              wish.isCompleted
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: wish.isCompleted
                  ? Theme.of(context).colorScheme.primary
                  : const Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              wish.title,
              style: TextStyle(
                fontSize: 16,
                decoration: wish.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _deleteWish(wish),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  void _addWish() {
    // TODO: 显示添加心愿对话框
  }

  void _toggleWish(Wish wish) {
    // TODO: 切换心愿完成状态
  }

  void _deleteWish(Wish wish) {
    // TODO: 删除心愿
  }
}
```

- [ ] **Step 3: 运行测试**

```bash
flutter test
```

Expected: 测试通过

- [ ] **Step 4: 提交代码**

```bash
git add lib/models/wish.dart lib/screens/couple/wish/wish_screen.dart
git commit -m "feat: 添加心愿清单功能"
```

---

## Phase 3 完成检查点

完成 Phase 3 后，你应该能够：
1. ✅ 管理心愿清单（添加、完成、删除）
2. ✅ 发送悄悄话消息
3. ✅ 切换主题颜色
4. ✅ 设置通知提醒

---

## Phase 4：小游戏

### Task 9: 游戏房间系统

**Files:**
- Create: `lib/models/game_room.dart`
- Create: `lib/screens/couple/game/game_select_screen.dart`
- Create: `lib/screens/couple/game/game_room_screen.dart`

- [ ] **Step 1: 创建 game_room.dart**

```dart
class GameRoom {
  final String id;
  final String roomCode;
  final String coupleId;
  final String gameType;
  final String status;
  final String player1Id;
  final String? player2Id;
  final bool player1Ready;
  final bool player2Ready;
  final Map<String, dynamic> gameData;
  final Map<String, dynamic>? result;

  GameRoom({
    required this.id,
    required this.roomCode,
    required this.coupleId,
    required this.gameType,
    this.status = 'waiting',
    required this.player1Id,
    this.player2Id,
    this.player1Ready = false,
    this.player2Ready = false,
    this.gameData = const {},
    this.result,
  });

  factory GameRoom.fromMap(Map<String, dynamic> map) {
    return GameRoom(
      id: map['objectId'],
      roomCode: map['room_code'],
      coupleId: map['couple_id'],
      gameType: map['game_type'],
      status: map['status'],
      player1Id: map['player1_id'],
      player2Id: map['player2_id'],
      player1Ready: map['player1_ready'] ?? false,
      player2Ready: map['player2_ready'] ?? false,
      gameData: Map<String, dynamic>.from(map['game_data'] ?? {}),
      result: map['result'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'room_code': roomCode,
      'couple_id': coupleId,
      'game_type': gameType,
      'status': status,
      'player1_id': player1Id,
      'player2_id': player2Id,
      'player1_ready': player1Ready,
      'player2_ready': player2Ready,
      'game_data': gameData,
      'result': result,
    };
  }

  bool get isReady => player1Ready && player2Ready;
  bool get isFull => player2Id != null;
}
```

- [ ] **Step 2: 创建 game_select_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'game_room_screen.dart';

class GameSelectScreen extends StatelessWidget {
  const GameSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('小游戏'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildGameCard(
              context,
              icon: Icons.quiz,
              label: '默契问答',
              description: '测测你们的默契度',
              gameType: 'quiz',
            ),
            const SizedBox(height: 16),
            _buildGameCard(
              context,
              icon: Icons.grid_view,
              label: '爱心消消乐',
              description: '经典配对小游戏',
              gameType: 'match',
            ),
            const SizedBox(height: 16),
            _buildGameCard(
              context,
              icon: Icons.draw,
              label: '你画我猜',
              description: '看看谁更懂你',
              gameType: 'draw',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required String gameType,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameRoomScreen(gameType: gameType),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: 创建 game_room_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GameRoomScreen extends StatefulWidget {
  final String gameType;

  const GameRoomScreen({
    super.key,
    required this.gameType,
  });

  @override
  State<GameRoomScreen> createState() => _GameRoomScreenState();
}

class _GameRoomScreenState extends State<GameRoomScreen> {
  String? _roomCode;
  bool _isPlayer1Ready = false;
  bool _isPlayer2Ready = false;
  bool _isPlayer2Joined = false;

  @override
  void initState() {
    super.initState();
    _createRoom();
  }

  Future<void> _createRoom() async {
    // TODO: 创建游戏房间，生成房间码
    setState(() {
      _roomCode = '123456'; // 临时
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('等待对方加入'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 房间码
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    '房间码',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _roomCode ?? '------',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: _roomCode ?? ''),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已复制房间码')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('复制房间码'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 玩家状态
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildPlayerStatus(
                    '我',
                    _isPlayer1Ready,
                  ),
                  const Divider(),
                  _buildPlayerStatus(
                    '对方',
                    _isPlayer2Ready,
                    isJoined: _isPlayer2Joined,
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // 邀请按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _invitePartner,
                icon: const Icon(Icons.share),
                label: const Text('发送房间码给对方'),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 准备按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _toggleReady,
                child: Text(_isPlayer1Ready ? '取消准备' : '准备'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerStatus(String name, bool isReady, {bool isJoined = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.person),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          if (!isJoined)
            const Text(
              '等待中...',
              style: TextStyle(
                color: Color(0xFF8E8E93),
              ),
            )
          else
            Icon(
              isReady ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isReady
                  ? Theme.of(context).colorScheme.primary
                  : const Color(0xFF8E8E93),
            ),
        ],
      ),
    );
  }

  void _invitePartner() {
    // TODO: 调用微信分享
  }

  void _toggleReady() {
    setState(() {
      _isPlayer1Ready = !_isPlayer1Ready;
    });
    // TODO: 更新房间状态
  }
}
```

- [ ] **Step 4: 运行测试**

```bash
flutter test
```

Expected: 测试通过

- [ ] **Step 5: 提交代码**

```bash
git add lib/models/game_room.dart lib/screens/couple/game/game_select_screen.dart lib/screens/couple/game/game_room_screen.dart
git commit -m "feat: 添加游戏房间系统"
```

---

## Phase 4 完成检查点

完成 Phase 4 后，你应该能够：
1. ✅ 创建游戏房间
2. ✅ 复制房间码邀请对方
3. ✅ 双方准备后开始游戏
4. ✅ 玩默契问答游戏

---

## Phase 5：完善优化

### Task 10: UI 细节打磨

- [ ] **Step 1: 添加启动页**
- [ ] **Step 2: 优化动画效果**
- [ ] **Step 3: 适配深色模式**
- [ ] **Step 4: 性能优化**

---

## 执行说明

**推荐执行方式：Subagent-Driven**

1. 使用 `superpowers:subagent-driven-development` 技能
2. 每个 Task 分配给独立的 subagent 执行
3. Task 之间进行 review
4. 快速迭代

**备选执行方式：Inline Execution**

1. 使用 `superpowers:executing-plans` 技能
2. 在当前会话中按顺序执行
3. 设置检查点进行 review

---

## 依赖关系

```
Task 1 (项目初始化)
    ↓
Task 2 (主题配置)
    ↓
Task 3 (LeanCloud 集成)
    ↓
Task 4 (登录页面)
    ↓
Task 5 (配对页面)
    ↓
Task 6 (首页)
    ↓
Task 7 (纪念日)
    ↓
Task 8 (心愿清单)
    ↓
Task 9 (游戏房间)
    ↓
Task 10 (完善优化)
```

---

## 注意事项

1. **微信登录配置**：需要在微信开放平台注册应用，获取 AppID
2. **LeanCloud 配置**：需要在 LeanCloud 控制台创建应用，获取 AppID 和 AppKey
3. **地图 SDK**：需要在腾讯地图开放平台申请 API Key
4. **测试**：每个 Task 完成后运行 `flutter test` 确保测试通过
5. **提交**：每个 Task 完成后提交代码，保持清晰的提交历史
