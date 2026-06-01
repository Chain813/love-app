import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/leancloud_service.dart';

/// 日记编辑页面
class DiaryEditScreen extends StatefulWidget {
  const DiaryEditScreen({super.key});

  @override
  State<DiaryEditScreen> createState() => _DiaryEditScreenState();
}

class _DiaryEditScreenState extends State<DiaryEditScreen> {
  final _contentController = TextEditingController();
  String _selectedMood = '😊';
  String _selectedWeather = '☀️';
  final List<String> _selectedTags = [];

  // 心情选项
  final List<Map<String, String>> _moods = [
    {'emoji': '🥰', 'text': '甜蜜'},
    {'emoji': '😊', 'text': '开心'},
    {'emoji': '😌', 'text': '平静'},
    {'emoji': '😢', 'text': '难过'},
    {'emoji': '😤', 'text': '生气'},
    {'emoji': '🥺', 'text': '想你'},
  ];

  // 天气选项
  final List<Map<String, String>> _weathers = [
    {'emoji': '☀️', 'text': '晴天'},
    {'emoji': '🌤️', 'text': '多云'},
    {'emoji': '☁️', 'text': '阴天'},
    {'emoji': '🌧️', 'text': '下雨'},
    {'emoji': '❄️', 'text': '下雪'},
    {'emoji': '🌈', 'text': '彩虹'},
  ];

  // 标签选项
  final List<Map<String, dynamic>> _tags = [
    {'icon': Icons.restaurant_rounded, 'text': '美食', 'color': const Color(0xFFFF9500)},
    {'icon': Icons.flight_takeoff_rounded, 'text': '旅行', 'color': const Color(0xFF5AC8FA)},
    {'icon': Icons.movie_creation_rounded, 'text': '电影', 'color': const Color(0xFFAF52DE)},
    {'icon': Icons.cake_rounded, 'text': '纪念日', 'color': const Color(0xFFFF6B9D)},
    {'icon': Icons.home_rounded, 'text': '居家', 'color': const Color(0xFF34C759)},
    {'icon': Icons.school_rounded, 'text': '学习', 'color': const Color(0xFF007AFF)},
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('写日记'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              '保存',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 心情选择
            _buildSectionTitle('今天心情如何？'),
            const SizedBox(height: 8),
            _buildEmojiSelector(
              items: _moods,
              selectedEmoji: _selectedMood,
              onSelected: (emoji, text) {
                setState(() {
                  _selectedMood = emoji;
                });
              },
            ),

            const SizedBox(height: 20),

            // 天气选择
            _buildSectionTitle('今天天气'),
            const SizedBox(height: 8),
            _buildEmojiSelector(
              items: _weathers,
              selectedEmoji: _selectedWeather,
              onSelected: (emoji, text) {
                setState(() {
                  _selectedWeather = emoji;
                });
              },
            ),

            const SizedBox(height: 20),

            // 内容输入
            _buildSectionTitle('记录今天'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: '今天发生了什么有趣的事...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 添加照片
            _buildSectionTitle('添加照片'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                // TODO: 打开相册
              },
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFC6C6C8),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_rounded,
                        size: 32,
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '点击添加照片',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 标签选择
            _buildSectionTitle('添加标签'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                final isSelected = _selectedTags.contains(tag['text'] as String);
                final tagColor = tag['color'] as Color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedTags.remove(tag['text'] as String);
                      } else {
                        _selectedTags.add(tag['text'] as String);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? tagColor.withValues(alpha: 0.12)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? Border.all(color: tagColor, width: 1.5)
                          : Border.all(color: const Color(0xFFE5E5EA)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tag['icon'] as IconData,
                          size: 16,
                          color: isSelected ? tagColor : tagColor.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tag['text'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected
                                ? tagColor
                                : const Color(0xFF8E8E93),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildEmojiSelector({
    required List<Map<String, String>> items,
    required String selectedEmoji,
    required void Function(String emoji, String text) onSelected,
  }) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selectedEmoji == item['emoji']!;
        return GestureDetector(
          onTap: () => onSelected(item['emoji']!, item['text']!),
          child: AnimatedScale(
            scale: isSelected ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.15)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: isSelected
                    ? Border.all(color: theme.colorScheme.primary, width: 2)
                    : Border.all(color: const Color(0xFFE5E5EA)),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Text(item['emoji']!, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 2),
                  Text(
                    item['text']!,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : const Color(0xFF8E8E93),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请写点什么再保存')),
      );
      return;
    }

    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await LeanCloudService.saveDiary(
        content: content,
        mood: _selectedMood,
        weather: _selectedWeather,
        tags: _selectedTags,
        date: todayStr,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('日记已同步到云端 ✨'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存日记失败：$e')),
        );
      }
    }
  }
}
