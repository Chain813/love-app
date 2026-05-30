import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/leancloud_service.dart';
import '../../utils/page_transitions.dart';
import 'diary_edit_screen.dart';
import 'package:animate_do/animate_do.dart';

/// 日记列表页面 - 支持联机同步与精美卡片渲染
class DiaryListScreen extends StatefulWidget {
  const DiaryListScreen({super.key});

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  List<Map<String, dynamic>> _diaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDiaries();
  }

  Future<void> _fetchDiaries() async {
    setState(() => _isLoading = true);
    try {
      final list = await LeanCloudService.fetchDiaries();
      setState(() {
        _diaries = list;
      });
    } catch (e) {
      debugPrint('获取日记列表失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载日记失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('恋爱日记 📖'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                FadeScaleRoute(page: const DiaryEditScreen()),
              );
              if (result == true) {
                _fetchDiaries();
              }
            },
            icon: const Icon(Icons.edit_note_rounded, size: 28),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDiaries,
              child: _diaries.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _diaries.length,
                      itemBuilder: (context, index) {
                        final diary = _diaries[index];
                        final dateStr = diary['date'] as String? ?? '';
                        final content = diary['content'] as String? ?? '';
                        final mood = diary['mood'] as String? ?? '😊';
                        final weather = diary['weather'] as String? ?? '☀️';
                        final tags = diary['tags'] as List<dynamic>? ?? [];

                        return FadeInUp(
                          duration: Duration(milliseconds: 400 + (index * 80)),
                          child: _DiaryCard(
                            dateStr: dateStr,
                            content: content,
                            mood: mood,
                            weather: weather,
                            tags: tags,
                            primaryColor: theme.colorScheme.primary,
                            onDelete: () => _confirmDelete(diary['objectId']),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FadeInUp(
        duration: const Duration(milliseconds: 600),
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              SlideUpRoute(page: const DiaryEditScreen()),
            );
            if (result == true) {
              _fetchDiaries();
            }
          },
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: FadeInUp(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.1),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Icon(
                Icons.auto_stories_rounded,
                size: 72,
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '还没有日记 📖',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF8E8E93),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '记录你们甜甜蜜蜜的恋爱点滴吧',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFC7C7CC),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  SlideUpRoute(page: const DiaryEditScreen()),
                );
                if (result == true) {
                  _fetchDiaries();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('写第一篇日记'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String objectId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除日记 🗑️'),
          content: const Text('您确定要永久删除这篇恋爱日记吗？这不会影响对方本地的数据。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认删除'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await LeanCloudService.deleteDiary(objectId);
        await _fetchDiaries();
      } catch (e) {
        debugPrint('删除失败: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// 日记卡片 — 带按下缩放微交互
class _DiaryCard extends StatefulWidget {
  final String dateStr, content, mood, weather;
  final List<dynamic> tags;
  final Color primaryColor;
  final VoidCallback onDelete;

  const _DiaryCard({
    required this.dateStr,
    required this.content,
    required this.mood,
    required this.weather,
    required this.tags,
    required this.primaryColor,
    required this.onDelete,
  });

  @override
  State<_DiaryCard> createState() => _DiaryCardState();
}

class _DiaryCardState extends State<_DiaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
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
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.dateStr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.mood} 心情 • ${widget.weather} 天气',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey),
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1C1C1E),
                  height: 1.6,
                ),
              ),
              if (widget.tags.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: widget.tags.map((t) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '# $t',
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
