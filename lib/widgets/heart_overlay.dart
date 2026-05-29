import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 屏幕发射爱心粒子上升特效 Overlay
class HeartOverlay {
  static void show(BuildContext context) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => _HeartOverlayWidget(
        onComplete: () {
          overlayEntry.remove();
        },
      ),
    );
    
    overlayState.insert(overlayEntry);
  }
}

class _HeartOverlayWidget extends StatefulWidget {
  final VoidCallback onComplete;
  
  const _HeartOverlayWidget({required this.onComplete});

  @override
  State<_HeartOverlayWidget> createState() => _HeartOverlayWidgetState();
}

class _HeartOverlayWidgetState extends State<_HeartOverlayWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_HeartParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // 持续 2 秒
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_particles.isEmpty) {
      final size = MediaQuery.of(context).size;
      // 生成 12-18 颗大小、颜色、摆动轨道随机的心形粒子
      for (int i = 0; i < 16; i++) {
        _particles.add(_HeartParticle(
          startX: size.width / 2 + (_random.nextDouble() - 0.5) * 120, // 从底部中间附近散射
          startY: size.height - 80,
          size: 16.0 + _random.nextDouble() * 24.0, // 16px - 40px
          speedY: 200.0 + _random.nextDouble() * 300.0, // 向上漂移速度
          amplitude: 20.0 + _random.nextDouble() * 40.0, // 左右正弦摇摆幅度
          frequency: 2.0 + _random.nextDouble() * 4.0, // 摇摆频率
          phase: _random.nextDouble() * math.pi * 2, // 初始随机相位
          color: _getRandomHeartColor(),
        ));
      }
    }
  }

  Color _getRandomHeartColor() {
    final colors = [
      const Color(0xFFFF2D55), // 苹果粉红
      const Color(0xFFFF5E7E), // 暖粉色
      const Color(0xFFFF85A1), // 柔粉色
      const Color(0xFFFFB3C6), // 亮樱花粉
      const Color(0xFFFFC0CB), // 标准粉红
      const Color(0xFFFF0844), // 热烈红
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        return IgnorePointer(
          child: Stack(
            children: _particles.map((particle) {
              // 随进度向上漂移
              final currentY = particle.startY - (particle.speedY * progress);
              // 正弦摆动公式
              final currentX = particle.startX + 
                  math.sin(progress * particle.frequency + particle.phase) * particle.amplitude;
              
              // 渐隐策略：前 15% 渐现，后 30% 渐隐
              double opacity = 1.0;
              if (progress < 0.15) {
                opacity = progress / 0.15;
              } else if (progress > 0.7) {
                opacity = (1.0 - progress) / 0.3;
              }
              opacity = opacity.clamp(0.0, 1.0);

              // 缩放策略：前 15% 从 0 放大，后 20% 缩小至 0
              double scale = 1.0;
              if (progress < 0.15) {
                scale = progress / 0.15;
              } else if (progress > 0.8) {
                scale = (1.0 - progress) / 0.2;
              }
              scale = scale.clamp(0.0, 1.0);

              return Positioned(
                left: currentX - (particle.size / 2),
                top: currentY - (particle.size / 2),
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Icon(
                      Icons.favorite_rounded,
                      size: particle.size,
                      color: particle.color,
                      shadows: [
                        Shadow(
                          color: particle.color.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _HeartParticle {
  final double startX;
  final double startY;
  final double size;
  final double speedY;
  final double amplitude;
  final double frequency;
  final double phase;
  final Color color;

  _HeartParticle({
    required this.startX,
    required this.startY,
    required this.size,
    required this.speedY,
    required this.amplitude,
    required this.frequency,
    required this.phase,
    required this.color,
  });
}
