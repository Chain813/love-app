import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';

Widget buildLocalImage(String path, {BoxFit fit = BoxFit.cover, Widget? placeholder}) {
  return ExtendedImage.network(
    path,
    fit: fit,
    loadStateChanged: (state) {
      if (state.extendedImageLoadState == LoadState.loading) {
        return placeholder ?? const SizedBox.shrink();
      }
      return null;
    },
  );
}

Widget buildLocalImageZoom(String path, {BoxFit fit = BoxFit.contain}) {
  return ExtendedImage.network(
    path,
    fit: fit,
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
  );
}
