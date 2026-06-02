import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/leancloud_service.dart';

/// 开发者管理后台 - 需要特定邮箱密码登录
class DeveloperAdminScreen extends StatefulWidget {
  final bool preAuthenticated;
  const DeveloperAdminScreen({super.key, this.preAuthenticated = false});

  @override
  State<DeveloperAdminScreen> createState() => _DeveloperAdminScreenState();
}

class _DeveloperAdminScreenState extends State<DeveloperAdminScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _error;

  // 管理员登录通过 AuthProvider 校验（已登录用户直接访问）

  // 数据
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _relations = [];
  int _totalUsers = 0;
  int _pairedUsers = 0;
  int _totalDiaries = 0;
  int _totalWishes = 0;

  // 自动刷新
  Timer? _refreshTimer;
  DateTime? _lastRefreshTime;

  // 视图模式
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    // 如果已通过登录页验证，直接进入后台
    if (widget.preAuthenticated) {
      _isLoggedIn = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDashboardData();
        _startAutoRefresh();
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isLoggedIn && mounted) {
        _loadDashboardData();
      }
    });
  }

  // 管理员邮箱白名单（在此添加允许访问后台的邮箱）
  static const _adminEmails = <String>{
    'admin@chongmi.com',
    // 在此添加你的邮箱
  };

  void _login() {
    final prov = context.read<AuthProvider>();
    if (!prov.isLoggedIn) {
      setState(() => _error = '请先登录后再访问管理后台');
      return;
    }

    // 校验管理员权限
    final userEmail = prov.currentUser?['email'] as String? ?? '';
    final username = prov.currentUser?['username'] as String? ?? '';
    if (!_adminEmails.contains(userEmail) && !_adminEmails.contains(username)) {
      setState(() => _error = '无权访问管理后台：您的账号不在管理员白名单中');
      return;
    }

    setState(() {
      _isLoggedIn = true;
      _error = null;
    });
    _loadDashboardData();
    _startAutoRefresh();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // 加载所有用户
      final users = await LeanCloudService.fetchAllLocations();
      _users = users;
      _totalUsers = users.length;
      _pairedUsers = users.where((u) => u['status'] == 'paired').length;

      // 加载配对关系
      _relations = await _fetchRelations();

      // 加载统计数据
      _totalDiaries = await _fetchCount('Diary');
      _totalWishes = await _fetchCount('Wish');
    } catch (e) {
      debugPrint('加载管理后台数据失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _lastRefreshTime = DateTime.now();
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRelations() async {
    try {
      // 通过 LeanCloudService 的方法获取
      final allUsers = await LeanCloudService.fetchAllLocations();
      final pairedUsers = allUsers.where((u) => u['couple_id'] != null).toList();

      // 按 couple_id 分组
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final user in pairedUsers) {
        final coupleId = user['couple_id'] as String?;
        if (coupleId != null) {
          grouped.putIfAbsent(coupleId, () => []);
          grouped[coupleId]!.add(user);
        }
      }

      return grouped.entries.map((e) => <String, dynamic>{
        'couple_id': e.key,
        'members': e.value,
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> _fetchCount(String table) async {
    // 返回 0，实际项目中可以通过 API 获取
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_isLoggedIn) {
      return _buildLoginScreen(theme);
    }

    return _buildDashboard(theme);
  }

  Widget _buildLoginScreen(ThemeData theme) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('开发者管理后台'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 图标
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '开发者管理后台',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '仅限开发者使用，请输入管理员凭证',
                style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
              ),
              const SizedBox(height: 40),

              // 表单
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: '管理员邮箱',
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF2F2F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: '管理员密码',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        filled: true,
                        fillColor: const Color(0xFFF2F2F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '登录',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // 错误提示
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(ThemeData theme) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: Column(
          children: [
            const Text('开发者管理后台'),
            if (_lastRefreshTime != null)
              Text(
                '最后更新: ${_formatTime(_lastRefreshTime!.toIso8601String())}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93)),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          // 实时刷新指示器
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '实时',
                  style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_showMap ? Icons.list_rounded : Icons.map_rounded),
            tooltip: _showMap ? '列表视图' : '地图视图',
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '立即刷新',
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: '退出管理',
            onPressed: () {
              _refreshTimer?.cancel();
              setState(() {
                _isLoggedIn = false;
                _emailController.clear();
                _passwordController.clear();
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showMap
              ? _buildMapView(theme)
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 统计卡片
                        _buildStatsGrid(theme),
                        const SizedBox(height: 24),

                        // 用户列表
                        const Text(
                          '用户列表',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildUserList(theme),

                        const SizedBox(height: 24),

                        // 配对关系
                        const Text(
                          '配对关系',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRelationList(theme),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatsGrid(ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: Icons.people_rounded,
          label: '总用户',
          value: '$_totalUsers',
          color: Colors.blue,
        ),
        _buildStatCard(
          icon: Icons.favorite_rounded,
          label: '已配对',
          value: '$_pairedUsers',
          color: Colors.pink,
        ),
        _buildStatCard(
          icon: Icons.auto_stories_rounded,
          label: '日记数',
          value: '$_totalDiaries',
          color: Colors.orange,
        ),
        _buildStatCard(
          icon: Icons.star_rounded,
          label: '心愿数',
          value: '$_totalWishes',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(ThemeData theme) {
    if (_users.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('暂无用户数据', style: TextStyle(color: Color(0xFF8E8E93))),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final nickname = user['nickname'] as String? ?? '未知';
        final email = user['email'] as String? ?? '';
        final status = user['status'] as String? ?? 'single';
        final inviteCode = user['invite_code'] as String? ?? '';
        final lat = user['latitude'] as double?;
        final lng = user['longitude'] as double?;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: status == 'paired'
                  ? Colors.pink.shade50
                  : Colors.grey.shade100,
              child: Icon(
                status == 'paired' ? Icons.favorite : Icons.person,
                color: status == 'paired' ? Colors.pink : Colors.grey,
                size: 20,
              ),
            ),
            title: Text(
              nickname,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (email.isNotEmpty)
                  Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: status == 'paired' ? Colors.pink.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status == 'paired' ? '已配对' : '单身',
                        style: TextStyle(
                          fontSize: 10,
                          color: status == 'paired' ? Colors.pink : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (inviteCode.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('已复制邀请码: $inviteCode')),
                          );
                        },
                        child: Text(
                          '邀请码: $inviteCode',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF8E8E93),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),
                if (lat != null && lng != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _openMap(lat, lng, nickname),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.blue.shade700),
                          const SizedBox(width: 4),
                          Text(
                            '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                            style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.open_in_new, size: 10, color: Colors.blue.shade700),
                        ],
                      ),
                    ),
                  ),
                  if (user['location_updated_at'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          if (_isRecentLocation(user['location_updated_at']))
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                '实时',
                                style: TextStyle(fontSize: 8, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                              ),
                            ),
                          Text(
                            '更新: ${_formatTime(user['location_updated_at'])}',
                            style: const TextStyle(fontSize: 9, color: Color(0xFFC7C7CC)),
                          ),
                        ],
                      ),
                    ),
                ] else
                  const Text(
                    '📍 未获取位置',
                    style: TextStyle(fontSize: 10, color: Color(0xFFC7C7CC)),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: () {
                final locInfo = lat != null && lng != null
                    ? '\n位置: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}'
                    : '';
                final info = '昵称: $nickname\n邮箱: $email\n状态: $status\n邀请码: $inviteCode$locInfo';
                Clipboard.setData(ClipboardData(text: info));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制用户信息')),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildRelationList(ThemeData theme) {
    if (_relations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('暂无配对关系', style: TextStyle(color: Color(0xFF8E8E93))),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _relations.length,
      itemBuilder: (context, index) {
        final relation = _relations[index];
        final coupleId = relation['couple_id'] as String;
        final members = relation['members'] as List<Map<String, dynamic>>;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.link_rounded, size: 16, color: Colors.pink),
                    const SizedBox(width: 6),
                    Text(
                      '配对 #${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      coupleId.length > 16 ? '${coupleId.substring(0, 16)}...' : coupleId,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...members.map((member) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        member['gender'] == 'female' ? Icons.female : Icons.male,
                        size: 16,
                        color: member['gender'] == 'female' ? Colors.pink : Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        member['nickname'] as String? ?? '未知',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      if (member['email'] != null)
                        Text(
                          member['email'] as String,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
                        ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openMap(double lat, double lng, String name) {
    // 复制坐标到剪贴板，用户可粘贴到任意地图 app
    final coord = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
    Clipboard.setData(ClipboardData(text: coord));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制坐标 $coord，请打开地图 app 搜索'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '打开高德',
          onPressed: () {
            // 高德地图深度链接（打开 app 版）
            final uri = Uri.parse('amap://marker?position=$lng,$lat&name=$name');
            launchUrl(uri).catchError((_) {
              // 如果没有安装高德，打开网页版
              final webUri = Uri.parse('https://uri.amap.com/marker?position=$lng,$lat&name=$name');
              launchUrl(webUri, mode: LaunchMode.externalApplication);
            });
          },
        ),
      ),
    );
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null || isoTime.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoTime);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
      if (diff.inHours < 24) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoTime;
    }
  }

  bool _isRecentLocation(String? isoTime) {
    if (isoTime == null || isoTime.isEmpty) return false;
    try {
      final dt = DateTime.parse(isoTime);
      final now = DateTime.now();
      return now.difference(dt).inMinutes < 5;
    } catch (e) {
      return false;
    }
  }

  Widget _buildMapView(ThemeData theme) {
    // 过滤有位置的用户
    final usersWithLocation = _users.where((u) {
      final lat = u['latitude'] as double?;
      final lng = u['longitude'] as double?;
      return lat != null && lng != null;
    }).toList();

    if (usersWithLocation.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('暂无用户位置数据', style: TextStyle(color: Color(0xFF8E8E93))),
          ],
        ),
      );
    }

    // 计算地图中心点
    double avgLat = 0, avgLng = 0;
    for (final u in usersWithLocation) {
      avgLat += (u['latitude'] as double);
      avgLng += (u['longitude'] as double);
    }
    avgLat /= usersWithLocation.length;
    avgLng /= usersWithLocation.length;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(avgLat, avgLng),
            initialZoom: usersWithLocation.length == 1 ? 15.0 : 10.0,
            minZoom: 3,
            maxZoom: 18,
          ),
          children: [
            // 高德地图瓦片
            TileLayer(
              urlTemplate: 'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}',
              subdomains: const ['1', '2', '3', '4'],
              userAgentPackageName: 'com.chongmi.app',
            ),
            // 用户标记
            MarkerLayer(
              markers: usersWithLocation.map((user) {
                final lat = user['latitude'] as double;
                final lng = user['longitude'] as double;
                final nickname = user['nickname'] as String? ?? '未知';
                final isRecent = _isRecentLocation(user['location_updated_at']);

                return Marker(
                  point: LatLng(lat, lng),
                  width: 120,
                  height: 60,
                  child: GestureDetector(
                    onTap: () => _showUserInfo(user),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isRecent ? Colors.green : Colors.blue,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            nickname,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.location_on,
                          color: isRecent ? Colors.green : Colors.blue,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        // 图例
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('实时 (5分钟内)', style: TextStyle(fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('历史位置', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showUserInfo(Map<String, dynamic> user) {
    final nickname = user['nickname'] as String? ?? '未知';
    final email = user['email'] as String? ?? '';
    final lat = user['latitude'] as double?;
    final lng = user['longitude'] as double?;
    final status = user['status'] as String? ?? 'single';
    final inviteCode = user['invite_code'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: status == 'paired' ? Colors.pink.shade50 : Colors.grey.shade100,
                    child: Icon(
                      status == 'paired' ? Icons.favorite : Icons.person,
                      color: status == 'paired' ? Colors.pink : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        if (email.isNotEmpty)
                          Text(email, style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'paired' ? Colors.pink.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status == 'paired' ? '已配对' : '单身',
                      style: TextStyle(
                        fontSize: 12,
                        color: status == 'paired' ? Colors.pink : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              if (lat != null && lng != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if (user['location_updated_at'] != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 24, top: 4),
                    child: Text(
                      '更新: ${_formatTime(user['location_updated_at'])}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openMap(lat, lng, nickname);
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('打开地图查看'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
