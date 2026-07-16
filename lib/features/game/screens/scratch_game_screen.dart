import 'dart:math';
import 'package:flutter/material.dart';
import 'package:scratcher/scratcher.dart';

/// 刮刮卡惊喜游戏
///
/// 刮开涂层查看对方准备的惊喜奖励。
class ScratchGameScreen extends StatefulWidget {
  const ScratchGameScreen({super.key});

  @override
  State<ScratchGameScreen> createState() => _ScratchGameScreenState();
}

class _ScratchGameScreenState extends State<ScratchGameScreen> {
  String _currentReward = '';
  double _scratchProgress = 0;
  bool _isRevealed = false;
  final _key = GlobalKey<ScratcherState>();

  static const _rewards = [
    '🫂 一个温暖的拥抱',
    '💋 一个甜蜜的吻',
    '💆 10分钟按摩',
    '🍳 TA为你做早餐',
    '🎬 陪你看一部电影',
    '🍰 请你吃甜品',
    '💌 一封手写情书',
    '🌹 一束鲜花',
    '🎵 为你唱一首歌',
    '🛁 帮你放好洗澡水',
    '☕ 早上的一杯咖啡',
    '🫶 无条件答应一个要求',
  ];

  void _newCard() {
    setState(() {
      _currentReward = _rewards[Random().nextInt(_rewards.length)];
      _scratchProgress = 0;
      _isRevealed = false;
    });
    _key.currentState?.reset();
  }

  @override
  void initState() {
    super.initState();
    _newCard();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('刮刮卡惊喜')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '刮开看看 TA 为你准备了什么？',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '用手指涂抹灰色区域',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 32),
              Scratcher(
                key: _key,
                brushSize: 45,
                threshold: 40,
                color: theme.colorScheme.primary,
                onChange: (value) {
                  setState(() => _scratchProgress = value);
                  if (value >= 0.4 && !_isRevealed) {
                    setState(() => _isRevealed = true);
                  }
                },
                child: Container(
                  width: 280,
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF6B9D),
                        const Color(0xFFFF8EB3).withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B9D).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentReward.split(' ').first,
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentReward.contains(' ')
                            ? _currentReward
                                .substring(_currentReward.indexOf(' ') + 1)
                            : _currentReward,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isRevealed
                    ? '🎉 已揭晓！'
                    : '已刮开 ${(_scratchProgress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  color: _isRevealed ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _newCard,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('再来一张'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
