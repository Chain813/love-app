import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../config/routes.dart';
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
  initialLocation: AppRoutes.login,
  debugLogDiagnostics: false,
  refreshListenable: auth,
  redirect: (context, state) {
    final isLoggedIn = auth.isLoggedIn;
    final isPaired = auth.isPaired;
    final isLoading = auth.isLoading;
    final path = state.matchedLocation;

    // 管理员页面仅已登录用户可访问
    if (path == AppRoutes.devAdmin) {
      if (!isLoggedIn) return AppRoutes.login;
      return null;
    }

    // 加载中不跳转
    if (isLoading) return null;

    // 未登录 → 去登录页（已在登录页则不跳转）
    if (!isLoggedIn && path != AppRoutes.login) {
      return AppRoutes.login;
    }

    // 已登录未配对 → 去配对页
    if (isLoggedIn && !isPaired && path != AppRoutes.pair) {
      return AppRoutes.pair;
    }

    // 已登录已配对 → 如果在登录/配对页则跳首页
    if (isLoggedIn && isPaired && (path == AppRoutes.login || path == AppRoutes.pair)) {
      return AppRoutes.home;
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.pair,
      builder: (context, state) => const PairScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.diary,
      builder: (context, state) => const DiaryListScreen(),
    ),
    GoRoute(
      path: AppRoutes.diaryEdit,
      builder: (context, state) => const DiaryEditScreen(),
    ),
    GoRoute(
      path: AppRoutes.photo,
      builder: (context, state) => const PhotoWallScreen(),
    ),
    GoRoute(
      path: AppRoutes.anniversary,
      builder: (context, state) => const AnniversaryScreen(),
    ),
    GoRoute(
      path: AppRoutes.wish,
      builder: (context, state) => const WishScreen(),
    ),
    GoRoute(
      path: AppRoutes.chat,
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: AppRoutes.gameSelect,
      builder: (context, state) => const GameSelectScreen(),
    ),
    GoRoute(
      path: AppRoutes.gameRoom,
      builder: (context, state) {
        final gameType = state.uri.queryParameters['type'] ?? 'quiz';
        return GameRoomScreen(gameType: gameType);
      },
    ),
    GoRoute(
      path: AppRoutes.period,
      builder: (context, state) => const PeriodIntimacyScreen(),
    ),
    GoRoute(
      path: AppRoutes.location,
      builder: (context, state) => const CoupleLocationScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.admin,
      builder: (context, state) => const AdminPanelScreen(),
    ),
    GoRoute(
      path: AppRoutes.devAdmin,
      builder: (context, state) => const DeveloperAdminScreen(),
    ),
  ],
);
