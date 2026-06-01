import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// 通用骨架屏加载组件
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// 列表卡片骨架屏
  static Widget card({double height = 100}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ShimmerLoading(
        height: height,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  /// 列表骨架屏（多条卡片）
  static Widget list({int itemCount = 5, double cardHeight = 100}) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (_, __) => card(height: cardHeight),
    );
  }

  /// 圆形头像骨架屏
  static Widget circle({double size = 48}) {
    return ShimmerLoading(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }

  /// 文本行骨架屏
  static Widget textLine({double width = 120, double height = 14}) {
    return ShimmerLoading(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(4),
    );
  }
}
