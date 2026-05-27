import 'package:flutter/material.dart';
import 'local_image_helper.dart'
    if (dart.library.js_util) 'local_image_helper_web.dart'
    if (dart.library.io) 'local_image_helper_mobile.dart';
import 'package:waterfall_flow/waterfall_flow.dart';
import 'package:extended_image/extended_image.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 照片网格组件 - 支持瀑布流与大图手势查看
class PhotoGrid extends StatelessWidget {
  final List<String> imageUrls;
  final int crossAxisCount;
  final double spacing;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final void Function(int index)? onPhotoTap;

  const PhotoGrid({
    super.key,
    required this.imageUrls,
    this.crossAxisCount = 2,
    this.spacing = 10,
    this.shrinkWrap = false,
    this.physics,
    this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              '还没有照片',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      );
    }

    return WaterfallFlow.builder(
      padding: EdgeInsets.all(spacing),
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        final url = imageUrls[index];
        // 根据索引模拟不同的宽高比，产生好看的瀑布流错落感
        final double aspectRatio = index % 3 == 0
            ? 0.7
            : index % 3 == 1
                ? 1.0
                : 0.85;

        return FadeInUp(
          duration: Duration(milliseconds: 300 + (index * 80)),
          child: GestureDetector(
            onTap: () {
              if (onPhotoTap != null) {
                onPhotoTap!(index);
              } else {
                // 默认弹窗放大查看照片
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenImageViewer(
                      imageUrls: imageUrls,
                      initialIndex: index,
                    ),
                  ),
                );
              }
            },
            child: Hero(
              tag: 'photo_$index',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: url.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: const Color(0xFFF2F2F7),
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: const Color(0xFFF2F2F7),
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          )
                        : buildLocalImage(
                            url,
                            fit: BoxFit.cover,
                            placeholder: Container(
                              color: const Color(0xFFF2F2F7),
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 大图手势缩放查看器
class FullScreenImageViewer extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: ExtendedImageGesturePageView.builder(
              itemBuilder: (BuildContext context, int index) {
                var item = imageUrls[index];
                return item.startsWith('http')
                    ? ExtendedImage.network(
                        item,
                        fit: BoxFit.contain,
                        mode: ExtendedImageMode.gesture,
                        initGestureConfigHandler: (state) {
                          return GestureConfig(
                            minScale: 0.9,
                            animationMinScale: 0.7,
                            maxScale: 3.0,
                            animationMaxScale: 3.5,
                            speed: 1.0,
                            inertialSpeed: 100.0,
                            initialScale: 1.0,
                            inPageView: true,
                            initialAlignment: InitialAlignment.center,
                          );
                        },
                        loadStateChanged: (ExtendedImageState state) {
                          switch (state.extendedImageLoadState) {
                            case LoadState.loading:
                              return const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              );
                            case LoadState.completed:
                              return null;
                            case LoadState.failed:
                              return const Center(
                                child: Icon(Icons.broken_image, color: Colors.white70, size: 48),
                              );
                          }
                        },
                      )
                    : buildLocalImageZoom(item, fit: BoxFit.contain);
              },
              itemCount: imageUrls.length,
              controller: ExtendedPageController(initialPage: initialIndex),
              scrollDirection: Axis.horizontal,
            ),
          ),
          // 顶部关闭与状态栏避让
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black38,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
