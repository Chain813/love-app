import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/diary_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/anniversary_card.dart';
import '../../../shared/widgets/heart_overlay.dart';
import '../../../shared/widgets/pulse_animation.dart';
import '../../diary/screens/diary_list_screen.dart';
import '../../photo/screens/photo_wall_screen.dart';
import 'package:animate_do/animate_do.dart';
import 'package:like_button/like_button.dart';
import '../../../services/leancloud_service.dart';
import '../../../services/llm_service.dart';
import '../../auth/screens/space_setup_screen.dart';

/// 首页 - 带底部导航栏
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isSetupNeeded = false;
  bool _checkingSetup = true;

  final List<Widget> _screens = const [
    _HomeContent(),
    DiaryListScreen(),
    PhotoWallScreen(),
    _CoupleContent(),
  ];

  @override
  void initState() {
    super.initState();
    _checkSetup();
  }

  Future<void> _checkSetup() async {
    final relation = await LeanCloudService.getLocalRelation() ??
        await LeanCloudService.checkPairStatus();
    if (relation == null ||
        relation['first_met_date'] == null ||
        (relation['first_met_date'] as String).isEmpty) {
      setState(() {
        _isSetupNeeded = true;
        _checkingSetup = false;
      });
    } else {
      setState(() {
        _isSetupNeeded = false;
        _checkingSetup = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSetup) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isSetupNeeded) {
      return SpaceSetupScreen(
        onSetupComplete: () {
          setState(() {
            _isSetupNeeded = false;
          });
        },
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5), width: 0.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AnimatedNavBarItem(
                    icon: Icons.home_rounded,
                    label: '首页',
                    isActive: _currentIndex == 0,
                    activeColor: theme.colorScheme.primary,
                    onTap: () => setState(() => _currentIndex = 0),
                  ),
                  _AnimatedNavBarItem(
                    icon: Icons.auto_stories_rounded,
                    label: '日记',
                    isActive: _currentIndex == 1,
                    activeColor: theme.colorScheme.primary,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                  _AnimatedNavBarItem(
                    icon: Icons.photo_library_rounded,
                    label: '相册',
                    isActive: _currentIndex == 2,
                    activeColor: theme.colorScheme.primary,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                  _AnimatedNavBarItem(
                    icon: Icons.favorite_rounded,
                    label: '互动',
                    isActive: _currentIndex == 3,
                    activeColor: theme.colorScheme.primary,
                    onTap: () => setState(() => _currentIndex = 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 底部导航栏弹性缩放项 — 带胶囊形背景指示器
class _AnimatedNavBarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;

  const _AnimatedNavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
  });

  @override
  State<_AnimatedNavBarItem> createState() => _AnimatedNavBarItemState();
}

class _AnimatedNavBarItemState extends State<_AnimatedNavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.75), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.75, end: 1.2), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 30),
    ]).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));
  }

  @override
  void didUpdateWidget(covariant _AnimatedNavBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _controller.forward(from: 0.0);
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        width: widget.isActive ? 72 : 56,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: widget.isActive
              ? widget.activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                widget.icon,
                color: widget.isActive
                    ? widget.activeColor
                    : const Color(0xFFAEAEB2),
                size: widget.isActive ? 24 : 22,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: widget.isActive ? 10 : 9,
                color: widget.isActive
                    ? widget.activeColor
                    : const Color(0xFFAEAEB2),
                fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    );
  }
}

/// 首页内容 - 采用高拟真 iOS 卡片式与情侣动态化设计
class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent>
    with TickerProviderStateMixin {
  int _loveClicks = 0;
  int _loveDays = 0;
  int _firstMetDays = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _relation;
  String _periodStatusTip = '';
  Color _periodStatusColor = Colors.grey;

  // 最新动态数据
  String _latestDiaryContent = '暂无日记';
  String _latestDiaryWeather = '';
  int _photoCount = 0;
  int _wishCompleted = 0;
  int _wishTotal = 0;
  DateTime? _anniversaryDate;
  String _anniversaryTitle = '在一起纪念日';
  String _anniversaryIcon = '🎂';

  // 每日金句
  String _dailyQuote = '';
  String _dailyQuoteAuthor = '';
  bool _quoteLoading = true;

  // 滚动数字动画
  late AnimationController _countUpController;
  late Animation<double> _countUpAnimation;

  @override
  void initState() {
    super.initState();
    _countUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _countUpAnimation = CurvedAnimation(
      parent: _countUpController,
      curve: Curves.easeOutCubic,
    );
    _loadData();
  }

  @override
  void dispose() {
    _countUpController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final relation = await LeanCloudService.getLocalRelation() ??
          await LeanCloudService.checkPairStatus();
      if (relation != null) {
        _relation = relation;
        _loveClicks = relation['heartbeat_count'] ?? 0;

        // 计算相恋天数
        final annivStr = relation['anniversary_date'] as String? ?? '';
        if (annivStr.isNotEmpty) {
          final annivDate = DateTime.tryParse(annivStr);
          if (annivDate != null) {
            _loveDays = DateTime.now().difference(annivDate).inDays + 1;
          }
        }

        // 计算初识天数
        final metStr = relation['first_met_date'] as String? ?? '';
        if (metStr.isNotEmpty) {
          final metDate = DateTime.tryParse(metStr);
          if (metDate != null) {
            _firstMetDays = DateTime.now().difference(metDate).inDays + 1;
          }
        }

        // 并行获取生理期和用户信息
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final results = await Future.wait([
          LeanCloudService.fetchPeriodLogs(),
          LeanCloudService.getCurrentUser(),
        ]);
        final periodLogs = results[0] as List<String>;
        final currentUser = results[1] as Map<String, dynamic>?;
        final currentUserId = currentUser?['objectId'];
        final isFemale = currentUser?['gender'] == 'female';

        final partnerName = relation['user1_id'] == currentUserId
            ? relation['user2_name']
            : relation['user1_name'];

        if (periodLogs.contains(todayStr)) {
          if (isFemale) {
            _periodStatusTip = '🔴 今天是您的生理期，请注意防寒保暖，多喝温水哦 🌸';
          } else {
            _periodStatusTip = '☕ $partnerName 今天处于生理期，请多关心 TA，递上一杯热水，多点陪伴吧！';
          }
          _periodStatusColor = const Color(0xFFE45C5C);
        } else {
          if (periodLogs.isNotEmpty) {
            periodLogs.sort();
            final lastPeriodStr = periodLogs.last;
            final lastPeriodDate = DateTime.tryParse(lastPeriodStr);
            if (lastPeriodDate != null) {
              final diff = DateTime.now().difference(lastPeriodDate).inDays;
              if (diff < 28) {
                final daysLeft = 28 - diff;
                if (isFemale) {
                  _periodStatusTip = '✨ 距离下一次生理期预计还有 $daysLeft 天，一切安好。';
                } else {
                  _periodStatusTip =
                      '✨ 距离 $partnerName 下一次生理期预计还有 $daysLeft 天。';
                }
                _periodStatusColor = const Color(0xFF68B77E);
              } else {
                if (isFemale) {
                  _periodStatusTip = '🌸 暂无生理期记录，若大姨妈已来访，请前往互动-生理助手标注哦。';
                } else {
                  _periodStatusTip = '🌸 $partnerName 今天身体状态良好，给予 TA 更多的拥抱吧。';
                }
                _periodStatusColor = Colors.pinkAccent;
              }
            }
          } else {
            _periodStatusTip = '🌸 还没有登记生理期记录，可从“互动-生理助手”日历进行手动标注。';
            _periodStatusColor = Colors.grey;
          }
        }
      }

      // 并行加载日记预览、心愿统计、纪念日
      await Future.wait([
        _loadDiaryPreview(),
        _loadWishStats(),
        _loadAnniversaryPreview(),
      ]).catchError((e) {
        debugPrint('并行加载数据失败: $e');
        return <void>[];
      });

      // 加载每日金句（异步，不阻塞首页渲染）
      _loadDailyQuote();
    } catch (e) {
      debugPrint('加载首页数据失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _countUpController.forward(from: 0.0);
      }
    }
  }

  Future<void> _loadDiaryPreview() async {
    try {
      final diaries = await LeanCloudService.fetchDiaries(limit: 1, offset: 0);
      if (diaries.isNotEmpty) {
        final latest = diaries.first;
        _latestDiaryContent = latest.content;
        _latestDiaryWeather = latest.weather;
        if (_latestDiaryContent.length > 20) {
          _latestDiaryContent = '${_latestDiaryContent.substring(0, 20)}...';
        }
      }
    } catch (_) {}
  }

  Future<void> _loadWishStats() async {
    try {
      final wishes = await LeanCloudService.fetchWishes();
      _wishTotal = wishes.length;
      _wishCompleted = wishes.where((w) => w['completed'] == true).length;
    } catch (_) {}
  }

  Future<void> _loadAnniversaryPreview() async {
    try {
      final anniversaries = await LeanCloudService.fetchAnniversaries();
      if (anniversaries.isNotEmpty) {
        final first = anniversaries.first;
        _anniversaryTitle = (first['title'] as String?) ?? '纪念日';
        _anniversaryIcon = (first['icon'] as String?) ?? '🎂';
        final dateStr = first['date'] as String?;
        if (dateStr != null) {
          _anniversaryDate = DateTime.tryParse(dateStr);
        }
      }
    } catch (_) {}
  }

  /// 加载每日金句（LLM 生成 + 缓存）
  Future<void> _loadDailyQuote() async {
    try {
      // 构建上下文
      String? coupleName;
      if (_relation != null) {
        final u1 = _relation!['user1_name'] as String? ?? '';
        final u2 = _relation!['user2_name'] as String? ?? '';
        if (u1.isNotEmpty && u2.isNotEmpty) {
          coupleName = '$u1 & $u2';
        }
      }

      final result = await LlmService.getDailyQuote(
        coupleName: coupleName,
        loveDays: _loveDays > 0 ? _loveDays : null,
      );
      if (mounted) {
        setState(() {
          _dailyQuote = result['quote'] ?? '';
          _dailyQuoteAuthor = result['author'] ?? '';
          _quoteLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载金句失败: $e');
      if (mounted) {
        setState(() => _quoteLoading = false);
      }
    }
  }

  Future<void> _sendLove() async {
    try {
      // 触发全屏发射爱心浮动气泡雨粒子动效
      HeartOverlay.show(context);

      final newCount = await LeanCloudService.sendHeartbeat();
      setState(() {
        _loveClicks = newCount;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text('已成功向对方发射爱心！联机总计 $newCount 次 💕'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('发射爱心错误: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 顶部情侣状态与交互头像区
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: _buildCoupleHeader(theme),
                ),

                const SizedBox(height: 24),

                // 2. 纪念看板：在一起天数统计
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: _buildLoveDashboard(theme),
                ),

                // 生理期温馨关怀 banner
                if (_periodStatusTip.isNotEmpty)
                  FadeInUp(
                    duration: const Duration(milliseconds: 900),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _periodStatusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: _periodStatusColor.withValues(alpha: 0.3),
                              width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.spa_rounded,
                                color: _periodStatusColor, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _periodStatusTip,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _periodStatusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // 3. 恋爱状态预览 - 卡片网格 (iOS Widget 风格)
                _buildWidgetGrid(theme),

                const SizedBox(height: 24),

                // 4. 每日金句 (Love Vows)
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  child: _buildLoveVowCard(theme),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 顶部情侣头像连接状态与“戳一戳/发射爱心”交互
  Widget _buildCoupleHeader(ThemeData theme) {
    final String user1Name = _relation?['user1_name'] ?? '';
    final String user2Name = _relation?['user2_name'] ?? '';
    final user1Gender = _relation?['user1_gender'] as String? ?? 'female';
    final user2Gender = _relation?['user2_gender'] as String? ?? 'male';
    final user1Emoji = user1Gender == 'female' ? '👩' : '👦';
    final user2Emoji = user2Gender == 'female' ? '👩' : '👦';
    final String coupleTitle = (user1Name.isNotEmpty && user2Name.isNotEmpty)
        ? '$user1Name & $user2Name'
        : '专属情侣空间';

    return Row(
      children: [
        // 情侣头像叠放连接区
        SizedBox(
          width: 90,
          height: 48,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: GlowPulse(
                  glowColor: const Color(0xFFFFD6E0),
                  glowRadius: 12,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD6E0),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(user1Emoji,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.favorite_rounded,
                      color: theme.colorScheme.primary, size: 18),
                ),
              ),
              Positioned(
                left: 42,
                child: GlowPulse(
                  glowColor: const Color(0xFFD6E4FF),
                  glowRadius: 12,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6E4FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(user2Emoji,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // 问候语
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '今天也是爱你的一天',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8E8E93),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                coupleTitle,
                style: TextStyle(
                  fontSize: 17,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // 互动动作：戳一戳
        LikeButton(
          size: 20,
          circleColor: CircleColor(
            start: const Color(0xFFFF2D55),
            end: theme.colorScheme.primary,
          ),
          bubblesColor: const BubblesColor(
            dotPrimaryColor: Color(0xFFFF2D55),
            dotSecondaryColor: Color(0xFFFF9500),
          ),
          onTap: (bool isLiked) async {
            await _sendLove();
            return !isLiked;
          },
          likeBuilder: (bool isLiked) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _loveClicks > 0 ? '发射爱心 ($_loveClicks)' : '发射爱心',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        // 设置按钮
        IconButton(
          onPressed: () {
            context.push('/settings');
          },
          icon: const Icon(Icons.settings_rounded),
          color: const Color(0xFF8E8E93),
        ),
      ],
    );
  }

  /// 恋爱天数统计看板卡片 — 带数字滚动动画
  Widget _buildLoveDashboard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.12),
            theme.colorScheme.primary.withValues(alpha: 0.04),
            theme.colorScheme.primary.withValues(alpha: 0.08),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_rounded,
                        size: 12, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '我们相恋了',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loveDays > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                AnimatedBuilder(
                  animation: _countUpAnimation,
                  builder: (context, child) {
                    final displayDays =
                        (_loveDays * _countUpAnimation.value).round();
                    return Text(
                      '$displayDays',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                        color: theme.colorScheme.onSurface,
                        height: 1.0,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                const Text('天',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8E8E93))),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: _countUpAnimation,
              builder: (context, child) {
                final displayMetDays =
                    (_firstMetDays * _countUpAnimation.value).round();
                return Text(
                  '初识至今已经 $displayMetDays 天 🌟',
                  style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                      fontWeight: FontWeight.w600),
                );
              },
            ),
          ] else ...[
            GestureDetector(
              onTap: () => context.push('/settings'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_calendar_rounded,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      '设置纪念日开始记录 💕',
                      style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// iOS 仿拟真小组件网格展示核心动态
  Widget _buildWidgetGrid(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInUp(
          duration: const Duration(milliseconds: 800),
          child: const Text(
            '最新动态',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        FadeInLeft(
          duration: const Duration(milliseconds: 900),
          child: Row(
            children: [
              // 左半边：日记动态小组件 (黄色调)
              Expanded(
                child: _buildInfoCard(
                  title: '日记随笔',
                  color: const Color(0xFFFF9500),
                  icon: Icons.auto_stories_rounded,
                  content: _latestDiaryWeather.isNotEmpty
                      ? '$_latestDiaryWeather $_latestDiaryContent'
                      : _latestDiaryContent,
                  onTap: () => context.push('/diary'),
                ),
              ),
              const SizedBox(width: 12),
              // 右半边：心愿进度小组件 (紫色调)
              Expanded(
                child: _buildProgressCard(
                  title: '相伴心愿',
                  color: const Color(0xFFAF52DE),
                  icon: Icons.star_rounded,
                  completed: _wishCompleted,
                  total: _wishTotal,
                  onTap: () {
                    context.push('/wish');
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FadeInRight(
          duration: const Duration(milliseconds: 950),
          child: Row(
            children: [
              // 左半边：相册合影预览小组件 (蓝色调)
              Expanded(
                child: _buildInfoCard(
                  title: '恋爱合影',
                  color: const Color(0xFF007AFF),
                  icon: Icons.photo_library_rounded,
                  content: _photoCount > 0
                      ? '📷 已上传 $_photoCount 张照片'
                      : '📷 还没有照片，快去上传吧',
                  onTap: () => context.push('/photo'),
                ),
              ),
              const SizedBox(width: 12),
              // 右半边：纪念日倒计时小组件 (粉红调)
              Expanded(
                child: _anniversaryDate != null
                    ? _buildInfoCard(
                        title: _anniversaryTitle,
                        color: const Color(0xFFFF6B9D),
                        icon: Icons.calendar_today_rounded,
                        content:
                            '$_anniversaryIcon ${_getAnniversaryCountdown()}',
                        onTap: () {
                          context.push('/anniversary');
                        },
                      )
                    : _buildInfoCard(
                        title: '纪念日',
                        color: const Color(0xFFFF6B9D),
                        icon: Icons.calendar_today_rounded,
                        content: '还没有纪念日，快去添加吧',
                        onTap: () {
                          context.push('/anniversary');
                        },
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 纪念日倒计时小组件 (大条卡片)
        if (_anniversaryDate != null)
          FadeInUp(
            duration: const Duration(milliseconds: 1000),
            child: GestureDetector(
              onTap: () {
                context.push('/anniversary');
              },
              child: AnniversaryCard(
                title: _anniversaryTitle,
                date: _anniversaryDate!,
                icon: _anniversaryIcon,
              ),
            ),
          ),
      ],
    );
  }

  /// 卡片基本模板 — 带按下缩放反馈
  String _getAnniversaryCountdown() {
    if (_anniversaryDate == null) return '';
    final now = DateTime.now();
    var nextDate =
        DateTime(now.year, _anniversaryDate!.month, _anniversaryDate!.day);
    if (nextDate.isBefore(now)) {
      nextDate = DateTime(
          now.year + 1, _anniversaryDate!.month, _anniversaryDate!.day);
    }
    final daysLeft = nextDate.difference(now).inDays;
    if (daysLeft == 0) return '就是今天！🎉';
    return '还有 $daysLeft 天';
  }

  Widget _buildInfoCard({
    required String title,
    required Color color,
    required IconData icon,
    required String content,
    required VoidCallback onTap,
  }) {
    return _PressableCard(
      onTap: onTap,
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1C1C1E),
                height: 1.4,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  /// 带进度条的卡片组件
  Widget _buildProgressCard({
    required String title,
    required Color color,
    required IconData icon,
    required int completed,
    required int total,
    required VoidCallback onTap,
  }) {
    final progress = completed / total;

    return _PressableCard(
      onTap: onTap,
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '已达成 $completed / $total 个心愿',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1C1C1E),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  /// 每日寄语卡片 (Love Oath/Vows) — 带渐变装饰条，LLM 生成 + 本地缓存
  Widget _buildLoveVowCard(ThemeData theme) {
    // 金句加载中显示骨架
    if (_quoteLoading) {
      return Container(
        width: double.infinity,
        height: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '每日一签',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8E8E93)),
                  ),
                  SizedBox(height: 8),
                  Text('✨ 正在为你生成今日金句...',
                      style: TextStyle(fontSize: 13, color: Color(0xFFC7C7CC))),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final quote = _dailyQuote.isNotEmpty
        ? _dailyQuote
        : '爱不是寻找一个完美的人，而是学会用完美的眼光去欣赏一个不完美的人。';
    final author = _dailyQuoteAuthor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '每日一签',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8E8E93)),
                      ),
                      if (author.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '— $author',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFC7C7CC),
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '“$quote”',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1C1C1E),
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 情侣互动页内容
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
                    icon: Icons.favorite_border_rounded,
                    label: '心愿清单',
                    description: '想和你一起做的事',
                    onTap: () {
                      context.push('/wish');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCard(
                    context,
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '悄悄话',
                    description: '甜蜜私语',
                    onTap: () {
                      context.push('/chat');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCard(
                    context,
                    icon: Icons.sports_esports_outlined,
                    label: '小游戏',
                    description: '一起玩耍的快乐时光',
                    onTap: () {
                      context.push('/game');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCard(
                    context,
                    icon: Icons.calendar_month_rounded,
                    label: '生理与亲密记',
                    description: '姨妈与爱爱日历标注',
                    onTap: () {
                      context.push('/period');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCard(
                    context,
                    icon: Icons.location_on_rounded,
                    label: '共享位置',
                    description: '看看TA在哪里',
                    onTap: () {
                      context.push('/location');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()), // 占位
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return _PressableCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                    theme.colorScheme.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                size: 28,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 通用按下缩放卡片组件 (Inline)
class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PressableCard({required this.child, this.onTap});

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
