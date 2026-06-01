import 'package:flutter/material.dart';
import '../../services/location_service.dart';

/// 定位权限请求弹窗
class LocationPermissionDialog extends StatelessWidget {
  const LocationPermissionDialog({super.key});

  /// 显示权限请求弹窗
  /// 返回 true = 用户同意请求权限, false = 用户拒绝
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LocationPermissionDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.location_on_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('开启定位服务'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '虫米想使用你的位置信息，用于：',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          _FeatureItem(
            icon: Icons.favorite_rounded,
            text: '与另一半共享实时位置',
          ),
          SizedBox(height: 8),
          _FeatureItem(
            icon: Icons.map_rounded,
            text: '在地图上查看彼此距离',
          ),
          SizedBox(height: 8),
          _FeatureItem(
            icon: Icons.security_rounded,
            text: '位置信息仅你和伴侣可见',
          ),
          SizedBox(height: 16),
          Text(
            '你的位置数据会安全存储，不会分享给第三方。你可以随时在设置中关闭定位。',
            style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93), height: 1.5),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('暂不开启', style: TextStyle(color: Color(0xFF8E8E93))),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('同意并开启'),
        ),
      ],
    );
  }
}

/// 定位被拒绝后的解释弹窗
class LocationDeniedDialog extends StatelessWidget {
  const LocationDeniedDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const LocationDeniedDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.location_off_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          const Text('定位权限未开启'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '定位功能需要你的授权才能使用。',
            style: TextStyle(fontSize: 15),
          ),
          SizedBox(height: 12),
          Text(
            '开启后你可以：\n• 与伴侣共享实时位置\n• 在地图上查看彼此距离\n• 记录你们一起去过的地方',
            style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93), height: 1.6),
          ),
          SizedBox(height: 12),
          Text(
            '请在系统设置中为虫米开启定位权限。',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('知道了', style: TextStyle(color: Color(0xFF8E8E93))),
        ),
        ElevatedButton(
          onPressed: () {
            LocationService.openLocationSettings();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('去设置'),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}
