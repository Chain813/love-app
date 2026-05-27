import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GameRoomScreen extends StatefulWidget {
  final String gameType;
  const GameRoomScreen({super.key, required this.gameType});

  @override
  State<GameRoomScreen> createState() => _GameRoomScreenState();
}

class _GameRoomScreenState extends State<GameRoomScreen> {
  String? _roomCode;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _roomCode = '${DateTime.now().millisecondsSinceEpoch % 1000000}'.padLeft(6, '0');
  }

  String get _gameTitle => switch (widget.gameType) {
    'quiz' => '默契问答',
    'match' => '爱心消消乐',
    'draw' => '你画我猜',
    _ => '小游戏',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_gameTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              Text('房间码', style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
              const SizedBox(height: 12),
              Text(_roomCode ?? '------', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 10, color: theme.colorScheme.primary)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _roomCode ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('已复制'), backgroundColor: theme.colorScheme.primary));
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('复制房间码'),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              _playerRow('我', true, _isReady, theme),
              const Divider(height: 24),
              _playerRow('对方', false, false, theme),
            ]),
          ),
          const Spacer(),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '我在虫米等你玩$_gameTitle！房间码：$_roomCode'));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('已复制邀请'), backgroundColor: theme.colorScheme.primary));
            },
            icon: const Icon(Icons.share_rounded),
            label: const Text('发送房间码给对方'),
          )),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 52, child: OutlinedButton(
            onPressed: () => setState(() => _isReady = !_isReady),
            child: Text(_isReady ? '取消准备' : '我准备好了'),
          )),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _playerRow(String name, bool joined, bool ready, ThemeData theme) {
    return Row(children: [
      CircleAvatar(radius: 18, backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15), child: Icon(Icons.person, size: 20, color: theme.colorScheme.primary)),
      const SizedBox(width: 12),
      Expanded(child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
      if (!joined) const Text('等待加入...', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14))
      else Icon(ready ? Icons.check_circle : Icons.radio_button_unchecked, color: ready ? theme.colorScheme.primary : const Color(0xFFC6C6C8), size: 22),
    ]);
  }
}
