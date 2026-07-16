import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:confetti/confetti.dart';

/// 约会大转盘游戏
///
/// 随机选择约会类型，解决"今天去哪"的选择困难。
class WheelGameScreen extends StatefulWidget {
  const WheelGameScreen({super.key});

  @override
  State<WheelGameScreen> createState() => _WheelGameScreenState();
}

class _WheelGameScreenState extends State<WheelGameScreen> {
  final StreamController<int> _controller = StreamController<int>();
  String? _result;
  late ConfettiController _confettiController;

  static const _items = [
    '🍽️ 浪漫晚餐',
    '🎬 看电影',
    '☕ 咖啡馆',
    '🌳 公园散步',
    '🎮 一起打游戏',
    '🍳 在家做饭',
    '🛍️ 逛街购物',
    '🎵 听音乐会',
    '🏖️ 海边日落',
    '📖 书店约会',
    '🧘 一起运动',
    '🎨 DIY 手工',
  ];

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _controller.close();
    _confettiController.dispose();
    super.dispose();
  }

  void _spin() {
    final idx = DateTime.now().millisecondsSinceEpoch % _items.length;
    _controller.add(idx);
    setState(() => _result = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('约会大转盘')),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '今天去哪约会？',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '转转盘，让命运决定吧 💫',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 300,
                  height: 300,
                  child: FortuneWheel(
                    selected: _controller.stream,
                    items: [
                      for (final item in _items)
                        FortuneItem(
                          child: Text(item,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                    ],
                    onAnimationEnd: () {
                      // result is set via onFling
                    },
                    onFling: () {
                      // Random result after spin
                      final idx =
                          DateTime.now().millisecondsSinceEpoch % _items.length;
                      _controller.add(idx);
                      Future.delayed(const Duration(seconds: 3), () {
                        setState(() => _result = _items[idx]);
                        _confettiController.play();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: _spin,
                  icon: const Icon(Icons.casino_rounded),
                  label: const Text('开始转动'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
                if (_result != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🎉 $_result',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [Colors.red, Colors.pink, Colors.orange, Colors.yellow],
              numberOfParticles: 30,
              maxBlastForce: 10,
              minBlastForce: 5,
            ),
          ),
        ],
      ),
    );
  }
}
