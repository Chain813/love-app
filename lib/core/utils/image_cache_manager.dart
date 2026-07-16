import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  /// 获取图片保存的目录
  Future<Directory> _getCacheDirectory() async {
    final docDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('/persistent_images');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// 将 URL 转换为安全的文件名
  String _urlToFilename(String url) {
    final bytes = utf8.encode(url);
    final base64String = base64UrlEncode(bytes);
    // 限制长度并去除特殊字符
    final safeName = base64String.replaceAll('=', '').replaceAll('/', '_').replaceAll('+', '-');
    return '.jpg';
  }

  /// 检查图片是否已存在于本地
  Future<File?> getLocalImage(String url) async {
    if (url.isEmpty || !url.startsWith('http')) return null;
    try {
      final cacheDir = await _getCacheDirectory();
      final file = File('/');
      if (await file.exists()) {
        return file;
      }
    } catch (e) {
      print('getLocalImage error: ');
    }
    return null;
  }

  /// 下载并持久化图片，返回本地文件路径
  Future<File?> downloadAndCacheImage(String url) async {
    if (url.isEmpty || !url.startsWith('http')) return null;

    try {
      // 如果已存在，直接返回
      final existingFile = await getLocalImage(url);
      if (existingFile != null) return existingFile;

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final cacheDir = await _getCacheDirectory();
        final file = File('/');
        await file.writeAsBytes(response.bodyBytes);
        print('Image cached permanently: ');
        return file;
      }
    } catch (e) {
      print('downloadAndCacheImage error:  -> ');
    }
    return null;
  }
}
