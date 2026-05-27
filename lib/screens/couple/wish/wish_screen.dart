import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:like_button/like_button.dart';
import 'package:animate_do/animate_do.dart';
import '../../../services/leancloud_service.dart';

/// 心愿清单页面 - 包含联机云端数据交互
class WishScreen extends StatefulWidget {
  const WishScreen({super.key});

  @override
  State<WishScreen> createState() => _WishScreenState();
}

class _WishScreenState extends State<WishScreen> {
  List<Map<String, dynamic>> _wishes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishes();
  }

  Future<void> _loadWishes() async {
    setState(() => _isLoading = true);
    try {
      final list = await LeanCloudService.fetchWishes();
      setState(() {
        _wishes = list;
      });
    } catch (e) {
      debugPrint('获取心愿清单失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addWish(String title) async {
    setState(() => _isLoading = true);
    try {
      await LeanCloudService.saveWish(title: title);
      await _loadWishes();
    } catch (e) {
      debugPrint('添加心愿失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleWish(String objectId, bool completed) async {
    try {
      await LeanCloudService.toggleWish(objectId, completed);
      // 本地乐观更新以提高流畅度，然后再刷新
      setState(() {
        final idx = _wishes.indexWhere((w) => w['objectId'] == objectId);
        if (idx != -1) {
          _wishes[idx]['completed'] = completed;
        }
      });
    } catch (e) {
      debugPrint('切换心愿状态失败: $e');
    }
  }

  Future<void> _deleteWish(String objectId) async {
    setState(() => _isLoading = true);
    try {
      await LeanCloudService.deleteWish(objectId);
      await _loadWishes();
    } catch (e) {
      debugPrint('删除心愿失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingWishes = _wishes.where((w) => !(w['completed'] as bool)).toList();
    final completedWishes = _wishes.where((w) => w['completed'] as bool).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('心愿清单 💖'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add_rounded, size: 28),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWishes,
              child: _wishes.isEmpty
                  ? FadeInUp(child: _buildEmptyState(theme))
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 待完成标题与卡片列表
                          if (pendingWishes.isNotEmpty) ...[
                            FadeInLeft(
                              duration: const Duration(milliseconds: 400),
                              child: const Text(
                                '甜蜜心愿待达成 ✨',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...pendingWishes.asMap().entries.map((entry) {
                              final itemIndex = _wishes.indexOf(entry.value);
                              return FadeInUp(
                                duration: Duration(milliseconds: 300 + entry.key * 80),
                                child: _buildPendingWishItem(entry.value, itemIndex, theme),
                              );
                            }),
                          ],

                          // 已完成标题与时间轴
                          if (completedWishes.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            FadeInLeft(
                              duration: const Duration(milliseconds: 400),
                              child: const Text(
                                '已达成的回忆印记 🎉',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: completedWishes.length,
                              itemBuilder: (context, idx) {
                                final item = completedWishes[idx];
                                final globalIndex = _wishes.indexOf(item);
                                return FadeInUp(
                                  duration: Duration(milliseconds: 300 + idx * 80),
                                  child: _buildCompletedWishTimelineTile(
                                    item,
                                    globalIndex,
                                    idx == 0,
                                    idx == completedWishes.length - 1,
                                    theme,
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_rounded,
            size: 72,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            '还没有心愿 ✨',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '添加你们想一起做的事情，共同编织未来',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFC7C7CC),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add),
            label: const Text('添加心愿'),
          ),
        ],
      ),
    );
  }

  /// 待完成的心愿卡片
  Widget _buildPendingWishItem(Map<String, dynamic> wish, int globalIndex, ThemeData theme) {
    final objectId = wish['objectId'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 粒子Checkbox
          LikeButton(
            size: 26,
            circleColor: CircleColor(
              start: const Color(0xFFFF2D55),
              end: theme.colorScheme.primary,
            ),
            bubblesColor: BubblesColor(
              dotPrimaryColor: theme.colorScheme.primary,
              dotSecondaryColor: const Color(0xFFFF9500),
            ),
            isLiked: false,
            likeBuilder: (bool isLiked) {
              return Container(
                decoration: BoxDecoration(
                  color: isLiked ? theme.colorScheme.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isLiked ? theme.colorScheme.primary : const Color(0xFFC6C6C8),
                    width: 2,
                  ),
                ),
                child: isLiked
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              );
            },
            onTap: (bool isLiked) async {
              // 延迟，等待爆炸动画播放完
              Future.delayed(const Duration(milliseconds: 450), () {
                _toggleWish(objectId, true);
              });
              return true;
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              wish['title'] as String,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _deleteWish(objectId),
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFC7C7CC)),
          ),
        ],
      ),
    );
  }

  /// 已完成的心愿时间轴Tile
  Widget _buildCompletedWishTimelineTile(
    Map<String, dynamic> wish,
    int globalIndex,
    bool isFirst,
    bool isLast,
    ThemeData theme,
  ) {
    final objectId = wish['objectId'] as String;

    return TimelineTile(
      alignment: TimelineAlign.start,
      isFirst: isFirst,
      isLast: isLast,
      indicatorStyle: IndicatorStyle(
        width: 22,
        height: 22,
        indicator: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.primary, width: 2),
          ),
          child: Icon(Icons.favorite_rounded, size: 11, color: theme.colorScheme.primary),
        ),
      ),
      beforeLineStyle: LineStyle(
        color: theme.colorScheme.primary.withValues(alpha: 0.25),
        thickness: 3,
      ),
      afterLineStyle: LineStyle(
        color: theme.colorScheme.primary.withValues(alpha: 0.25),
        thickness: 3,
      ),
      endChild: Container(
        margin: const EdgeInsets.only(left: 16, bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF2F2F7)),
        ),
        child: Row(
          children: [
            // 点击可回退为待办
            GestureDetector(
              onTap: () => _toggleWish(objectId, false),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, size: 14, color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                wish['title'] as String,
                style: const TextStyle(
                  fontSize: 15,
                  decoration: TextDecoration.lineThrough,
                  color: Color(0xFF8E8E93),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _deleteWish(objectId),
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFC7C7CC)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '添加甜蜜心愿 💖',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '想和你一起去海边/看日出/看演唱会...',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    _addWish(text);
                    Navigator.pop(context);
                  },
                  child: const Text('添加'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
