import 'package:flutter/material.dart';

Widget buildLocalImage(String path, {BoxFit fit = BoxFit.cover, Widget? placeholder}) {
  return placeholder ?? const SizedBox.shrink();
}

Widget buildLocalImageZoom(String path, {BoxFit fit = BoxFit.contain}) {
  return const Center(child: Icon(Icons.broken_image, color: Colors.white));
}
