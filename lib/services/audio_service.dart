import 'package:audioplayers/audioplayers.dart';

/// 音效管理服务
class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  final Map<String, AudioPlayer> _players = {};

  /// 播放心跳音效
  Future<void> playHeartbeat() async {
    await _play('heartbeat');
  }

  /// 播放完成音效
  Future<void> playComplete() async {
    await _play('complete');
  }

  /// 播放消息提示音
  Future<void> playMessage() async {
    await _play('message');
  }

  /// 播放音效（使用系统默认音效）
  Future<void> _play(String name) async {
    try {
      // 使用 AssetSource 播放本地音效文件
      // 如果文件不存在，静默失败
      final player = AudioPlayer();
      _players[name] = player;
      await player.play(AssetSource('audio/$name.mp3'));
      // 播放完成后释放
      player.onPlayerComplete.listen((_) {
        player.dispose();
        _players.remove(name);
      });
    } catch (e) {
      // 音效文件不存在时静默失败，不影响主功能
    }
  }

  /// 释放所有播放器
  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
  }
}
