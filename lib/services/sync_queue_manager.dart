import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'leancloud_service.dart';

class SyncQueueManager {
  static final SyncQueueManager _instance = SyncQueueManager._internal();
  factory SyncQueueManager() => _instance;
  SyncQueueManager._internal();

  late Box _syncQueueBox;
  StreamSubscription? _connectivitySubscription;
  bool _isProcessing = false;

  void init() {
    _syncQueueBox = Hive.box('sync_queue');
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
    // 启动时也尝试处理一次
    _processQueue();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// 将任务加入离线同步队列
  Future<void> enqueueTask(String type, Map<String, dynamic> payload) async {
    final task = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': type,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _syncQueueBox.add(task);
    print('Task enqueued: ');
    
    // 如果当前有网，则立即触发处理
    _processQueue();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _syncQueueBox.isEmpty) return;
    
    final connectivityResult = await Connectivity().checkConnectivity();
    if (!connectivityResult.contains(ConnectivityResult.mobile) && 
        !connectivityResult.contains(ConnectivityResult.wifi)) {
      return;
    }

    _isProcessing = true;
    try {
      final tasks = _syncQueueBox.values.toList();
      for (var i = 0; i < tasks.length; i++) {
        final task = Map<String, dynamic>.from(tasks[i] as Map);
        final success = await _executeTask(task);
        if (success) {
          // 删除该任务
          await _syncQueueBox.deleteAt(0); // 始终删除第一个，因为上一个成功后顶部的就是当前的
        } else {
          // 遇到失败的任务则中断处理，等待下次重试
          break;
        }
      }
    } catch (e) {
      print('Error processing sync queue: ');
    } finally {
      _isProcessing = false;
    }
  }

  Future<bool> _executeTask(Map<String, dynamic> task) async {
    final type = task['type'] as String;
    final payload = task['payload'] as Map<String, dynamic>;

    try {
      switch (type) {
        case 'saveDiary':
          await LeanCloudService.saveDiary(
            objectId: payload['objectId'],
            content: payload['content'],
            mood: payload['mood'],
            weather: payload['weather'],
            tags: List<String>.from(payload['tags'] ?? []),
            date: payload['date'],
            imageUrl: payload['imageUrl'],
          );
          return true;
        case 'deleteDiary':
          await LeanCloudService.deleteDiary(payload['objectId']);
          return true;
        // 其他模型可根据需求逐步扩展
        default:
          print('Unknown task type: ');
          return true; // 未知任务直接丢弃
      }
    } catch (e) {
      print('Task execution failed: ');
      return false; // 失败将保留任务并在以后重试
    }
  }
}
