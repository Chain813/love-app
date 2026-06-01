import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/pair_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/diary/diary_list_screen.dart';
import '../screens/diary/diary_edit_screen.dart';
import '../screens/photo/photo_wall_screen.dart';
import '../screens/anniversary/anniversary_screen.dart';
import '../screens/couple/wish/wish_screen.dart';
import '../screens/couple/chat/chat_screen.dart';
import '../screens/couple/game/game_select_screen.dart';
import '../screens/couple/game/game_room_screen.dart';
import '../screens/couple/period_intimacy_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/location/couple_location_screen.dart';
import '../screens/admin/admin_panel_screen.dart';
import '../screens/admin/developer_admin_screen.dart';

/// 全局路由配置
/// 支持 Web 端浏览器前进/后退、URL 深链接
GoRouter createRouter(AuthProvider auth) => GoRouter(
  initialLocation: '/login',
  debugLogDiagnostics: false,
  refreshListenable: auth,
  redirect: (context, state) {
    final isLoggedIn = auth.isLoggedIn;
    final isPaired = auth.isPaired;
    final isLoading = auth.isLoading;
    final path = state.matchedLocation;

    // 管理员页面豁免重定向
    if (path == '/dev-admin') return null;

    // 加载中不跳转
    if (isLoading) return null;

    // 未登录 → 去登录页（已在登录页则不跳转）
    if (!isLoggedIn && path != '/login') {
      return '/login';
    }

    // 已登录未配对 → 去配对页
    if (isLoggedIn && !isPaired && path != '/pair') {
      return '/pair';
    }

    // 已登录已配对 → 如果在登录/配对页则跳首页
    if (isLoggedIn && isPaired && (path == '/login' || path == '/pair')) {
      return '/home';
    }

    return null;
  },
  routes: [
    // 登录页
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    // 配对页
    GoRoute(
      path: '/pair',
      builder: (context, state) => const PairScreen(),
    ),

    // 首页（ShellRoute 包裹底部导航）
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),

    // 日记列表
    GoRoute(
      path: '/diary',
      builder: (context, state) => const DiaryListScreen(),
    ),

    // 日记编辑
    GoRoute(
      path: '/diary/edit',
      builder: (context, state) => const DiaryEditScreen(),
    ),

    // 照片墙
    GoRoute(
      path: '/photo',
      builder: (context, state) => const PhotoWallScreen(),
    ),

    // 纪念日
    GoRoute(
      path: '/anniversary',
      builder: (context, state) => const AnniversaryScreen(),
    ),

    // 心愿清单
    GoRoute(
      path: '/wish',
      builder: (context, state) => const WishScreen(),
    ),

    // 悄悄话
    GoRoute(
      path: '/chat',
      builder: (context, state) => const ChatScreen(),
    ),

    // 游戏选择
    GoRoute(
      path: '/game',
      builder: (context, state) => const GameSelectScreen(),
    ),

    // 游戏房间
    GoRoute(
      path: '/game/room',
      builder: (context, state) {
        final gameType = state.uri.queryParameters['type'] ?? 'quiz';
        return GameRoomScreen(gameType: gameType);
      },
    ),

    // 生理与亲密记
    GoRoute(
      path: '/period',
      builder: (context, state) => const PeriodIntimacyScreen(),
    ),

    // 共享位置
    GoRoute(
      path: '/location',
      builder: (context, state) => const CoupleLocationScreen(),
    ),

    // 设置
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),

    // 管理员面板
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminPanelScreen(),
    ),

    // 开发者管理后台
    GoRoute(
      path: '/dev-admin',
      builder: (context, state) {
        final authenticated = state.uri.queryParameters['auth'] == '1';
        return DeveloperAdminScreen(preAuthenticated: authenticated);
      },
    ),
  ],
);
