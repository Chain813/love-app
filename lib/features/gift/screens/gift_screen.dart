import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../services/leancloud_service.dart';
import '../models/gift.dart';

/// 积分赠礼页面
///
/// 情侣双方可在此页面上架礼物（设定积分值），对方用积分兑换。
/// 积分通过每日互动（发射爱心、写日记等）累积。
class GiftScreen extends StatefulWidget {
  const GiftScreen({super.key});

  @override
  State<GiftScreen> createState() => _GiftScreenState();
}

class _GiftScreenState extends State<GiftScreen> {
  List<Gift> _gifts = [];
  int _myPoints = 0;
  String? _myUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await LeanCloudService.getCurrentUser();
      _myUserId = user?['objectId']?.toString();

      // Load gifts from local Hive box
      final box = Hive.box('gifts');
      final raw = box.get('list', defaultValue: <dynamic>[]) as List;
      _gifts = raw
          .map((e) => Gift.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      // Calculate points from heartbeat count
      final relation = await LeanCloudService.getLocalRelation();
      _myPoints = (relation?['heartbeat_count'] as num?)?.toInt() ?? 0;

      // Deduct points already spent on redeemed gifts
      final myRedeemed = _gifts
          .where((g) => g.redeemedBy == _myUserId)
          .fold<int>(0, (sum, g) => sum + g.points);
      _myPoints -= myRedeemed;
      if (_myPoints < 0) _myPoints = 0;
    } catch (e) {
      debugPrint('加载礼物数据失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addGift() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final pointsCtrl = TextEditingController();
    String selectedIcon = '🎁';
    final icons = ['🎁', '💐', '🍰', '🎂', '💍', '🌹', '🎵', '📖', '🎮', '✈️', '💌', '🍫'];

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('上架新礼物'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: '礼物名称',
                    hintText: '例如：一顿大餐',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: '描述（可选）',
                    hintText: '例如：周末去吃你喜欢的那家日料',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pointsCtrl,
                  decoration: const InputDecoration(
                    labelText: '所需积分',
                    hintText: '例如：100',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: icons.map((icon) {
                    final isSelected = selectedIcon == icon;
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedIcon = icon),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.15)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(icon, style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.isEmpty || pointsCtrl.text.isEmpty) return;
                Navigator.pop(ctx, {
                  'title': titleCtrl.text,
                  'description': descCtrl.text,
                  'points': pointsCtrl.text,
                  'icon': selectedIcon,
                });
              },
              child: const Text('上架'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    final gift = Gift(
      id: const Uuid().v4(),
      coupleId: '',
      title: result['title']!,
      description: result['description'] ?? '',
      points: int.tryParse(result['points']!) ?? 0,
      icon: result['icon'] ?? '🎁',
      createdBy: _myUserId ?? '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final box = Hive.box('gifts');
    final raw = box.get('list', defaultValue: <dynamic>[]) as List;
    raw.insert(0, gift.toJson());
    await box.put('list', raw);

    _loadData();
  }

  Future<void> _redeemGift(Gift gift) async {
    if (_myPoints < gift.points) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('积分不足！还需要 ${gift.points - _myPoints} 分'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('兑换 ${gift.title}'),
        content: Text('消耗 ${gift.points} 积分兑换此礼物，确定吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认兑换'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final updated = gift.copyWith(
      redeemedBy: _myUserId,
      redeemedAt: DateTime.now(),
    );

    final box = Hive.box('gifts');
    final raw = box.get('list', defaultValue: <dynamic>[]) as List;
    final idx = raw.indexWhere(
        (e) => (e as Map)['objectId'] == gift.id);
    if (idx != -1) {
      raw[idx] = updated.toJson();
      await box.put('list', raw);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 成功兑换「${gift.title}」！'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final availableGifts =
        _gifts.where((g) => !g.isRedeemed && g.createdBy != _myUserId).toList();
    final myGifts = _gifts.where((g) => g.createdBy == _myUserId).toList();
    final redeemedGifts = _gifts.where((g) => g.isRedeemed).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('积分赠礼'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '$_myPoints',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addGift,
        icon: const Icon(Icons.add),
        label: const Text('上架礼物'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Points info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.12),
                  theme.colorScheme.primary.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '我的积分: $_myPoints',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '每天发射爱心、写日记都能获得积分',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Available gifts to redeem
          if (availableGifts.isNotEmpty) ...[
            _sectionTitle('可兑换的礼物', theme),
            const SizedBox(height: 12),
            ...availableGifts.map((g) => _giftCard(g, theme, isMine: false)),
          ],

          // My listed gifts
          if (myGifts.isNotEmpty) ...[
            const SizedBox(height: 24),
            _sectionTitle('我上架的礼物', theme),
            const SizedBox(height: 12),
            ...myGifts.map((g) => _giftCard(g, theme, isMine: true)),
          ],

          // Redeemed gifts
          if (redeemedGifts.isNotEmpty) ...[
            const SizedBox(height: 24),
            _sectionTitle('已兑换', theme),
            const SizedBox(height: 12),
            ...redeemedGifts.map((g) => _giftCard(g, theme, isMine: true, isRedeemed: true)),
          ],

          if (_gifts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Column(
                  children: [
                    const Text('🎁', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text(
                      '还没有礼物\n点击右下角上架第一个吧',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _giftCard(Gift gift, ThemeData theme,
      {bool isMine = false, bool isRedeemed = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Text(gift.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gift.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (gift.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      gift.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isRedeemed)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '已兑换 ✓',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              )
            else if (isMine)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${gift.points} ⭐',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () => _redeemGift(gift),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${gift.points} ⭐ 兑换',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
