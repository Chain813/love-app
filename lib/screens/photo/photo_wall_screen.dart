import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/photo_grid.dart';

/// 相册墙页面
class PhotoWallScreen extends StatefulWidget {
  const PhotoWallScreen({super.key});

  @override
  State<PhotoWallScreen> createState() => _PhotoWallScreenState();
}

class _PhotoWallScreenState extends State<PhotoWallScreen> {
  final List<String> _imageUrls = [
    'https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=600&fit=crop&q=80',
    'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?w=600&fit=crop&q=80',
    'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=600&fit=crop&q=80',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&fit=crop&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600&fit=crop&q=80',
    'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=600&fit=crop&q=80',
    'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600&fit=crop&q=80',
    'https://images.unsplash.com/photo-1464746133101-a2c3f88e0dd9?w=600&fit=crop&q=80',
  ];

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          // 将选中的本地图片路径加入相册列表头部
          _imageUrls.insert(0, image.path);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('照片上传成功！已加入相册墙 ✨'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('上传失败: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('相册墙'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _pickImage,
            icon: const Icon(Icons.add_a_photo_rounded),
            tooltip: '上传照片',
          ),
        ],
      ),
      body: _imageUrls.isEmpty
          ? _buildEmptyState()
          : PhotoGrid(
              imageUrls: _imageUrls,
              crossAxisCount: 2,
              spacing: 12,
            ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_rounded,
            size: 72,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            '还没有照片',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '记录你们在一起的每一个瞬间',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFC7C7CC),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('上传第一张照片'),
          ),
        ],
      ),
    );
  }
}
