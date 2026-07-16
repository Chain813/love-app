import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/utils/image_cache_manager.dart';

class PersistentNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const PersistentNetworkImage({
    Key? key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  _PersistentNetworkImageState createState() => _PersistentNetworkImageState();
}

class _PersistentNetworkImageState extends State<PersistentNetworkImage> {
  File? _localFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(PersistentNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final manager = ImageCacheManager();
    // 首先尝试获取已下载的本地文件
    var file = await manager.getLocalImage(widget.imageUrl);
    
    if (file != null) {
      if (mounted) {
        setState(() {
          _localFile = file;
          _isLoading = false;
        });
      }
      return;
    }

    // 尚未下载，触发静默下载，同时使用 CachedNetworkImage 作为临时展示
    if (mounted) {
      setState(() {
        _localFile = null;
        _isLoading = false;
      });
    }

    // 在后台下载并永久保存
    manager.downloadAndCacheImage(widget.imageUrl).then((newFile) {
      if (newFile != null && mounted) {
        setState(() {
          _localFile = newFile;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ?? _defaultPlaceholder();
    }

    if (_localFile != null) {
      return Image.file(
        _localFile!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) => widget.errorWidget ?? _defaultError(),
      );
    }

    // Fallback: 如果还在下载中，使用 CachedNetworkImage 临时展示
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      placeholder: (context, url) => widget.placeholder ?? _defaultPlaceholder(),
      errorWidget: (context, url, error) => widget.errorWidget ?? _defaultError(),
    );
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _defaultError() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
