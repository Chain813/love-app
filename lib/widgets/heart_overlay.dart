import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 屏幕发射爱心粒子上升特效 Overlay — 增强版
/// 包含心形 + 星形混合粒子，带旋转和生命周期缩放
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
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
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
      // 生成 22 颗混合粒子
      for (int i = 0; i < 22; i++) {
        final isHeart = _random.nextDouble() > 0.35; // 65% 心形, 35% 星形
        _particles.add(_Particle(
          startX: size.width / 2 + (_random.nextDouble() - 0.5) * 140,
          startY: size.height - 80,
          size: 14.0 + _random.nextDouble() * 26.0,
          speedY: 180.0 + _random.nextDouble() * 320.0,
          amplitude: 18.0 + _random.nextDouble() * 45.0,
          frequency: 2.0 + _random.nextDouble() * 4.0,
          phase: _random.nextDouble() * math.pi * 2,
          rotation: _random.nextDouble() * math.pi * 2,
          rotationSpeed: (_random.nextDouble() - 0.5) * 4.0,
          color: _getRandomColor(),
          isHeart: isHeart,
        ));
      }
    }
  }

  Color _getRandomColor() {
    final colors = [
      const Color(0xFFFF2D55),
      const Color(0xFFFF5E7E),
      const Color(0xFFFF85A1),
      const Color(0xFFFFB3C6),
      const Color(0xFFFFC0CB),
      const Color(0xFFFF0844),
      const Color(0xFFFFD700), // 金色星形
      const Color(0xFFFFA6C9),
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
              final currentY = particle.startY - (particle.speedY * progress);
              final currentX = particle.startX + 
                  math.sin(progress * particle.frequency + particle.phase) * particle.amplitude;
              
              // 渐隐：前 12% 渐现，后 25% 渐隐
              double opacity = 1.0;
              if (progress < 0.12) {
                opacity = progress / 0.12;
              } else if (progress > 0.75) {
                opacity = (1.0 - progress) / 0.25;
              }
              opacity = opacity.clamp(0.0, 1.0);

              // 生命周期缩放：弹入 → 稳定 → 缩小消失
              double scale = 1.0;
              if (progress < 0.12) {
                scale = Curves.easeOutBack.transform(progress / 0.12);
              } else if (progress > 0.8) {
                scale = Curves.easeIn.transform((1.0 - progress) / 0.2);
              }
              scale = scale.clamp(0.0, 1.5);

              final currentRotation = particle.rotation + particle.rotationSpeed * progress;

              return Positioned(
                left: currentX - (particle.size / 2),
                top: currentY - (particle.size / 2),
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Transform.rotate(
                      angle: currentRotation,
                      child: Icon(
                        particle.isHeart 
                            ? Icons.favorite_rounded 
                            : Icons.star_rounded,
                        size: particle.size,
                        color: particle.color,
                        shadows: [
                          Shadow(
                            color: particle.color.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
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

class _Particle {
  final double startX;
  final double startY;
  final double size;
  final double speedY;
  final double amplitude;
  final double frequency;
  final double phase;
  final double rotation;
  final double rotationSpeed;
  final Color color;
  final bool isHeart;

  _Particle({
    required this.startX,
    required this.startY,
    required this.size,
    required this.speedY,
    required this.amplitude,
    required this.frequency,
    required this.phase,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.isHeart,
  });
}
