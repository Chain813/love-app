import 'package:hive/hive.dart';

/// Hive 列表数据读写工具 — 消除重复的序列化样板代码
///
/// 全项目 30+ 处重复模式：
///   final raw = box.get('list') ?? [];
///   final list = List<Map<String, dynamic>>.from(
///     raw.map((e) => Map<String, dynamic>.from(e as Map))
///   );
///
/// 使用方式：
///   final diaries = HiveListHelper.readList(box);
///   HiveListHelper.writeList(box, diaries);
///   HiveListHelper.upsertInList(box, diary, (d) => d['objectId'] == newId);
///   HiveListHelper.removeFromList(box, (d) => d['objectId'] == targetId);
class HiveListHelper {
  /// 读取列表（自动处理 null 和类型转换）
  static List<Map<String, dynamic>> readList(Box box, {String key = 'list'}) {
    final raw = box.get(key);
    if (raw == null || raw is! List) return [];
    return List<Map<String, dynamic>>.from(
      raw.map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  /// 写入列表
  static Future<void> writeList(Box box, List<Map<String, dynamic>> list, {String key = 'list'}) async {
    await box.put(key, list);
  }

  /// 插入或更新一条记录（按 predicate 匹配）
  static Future<void> upsertInList(
    Box box,
    Map<String, dynamic> item,
    bool Function(Map<String, dynamic> existing) match, {
    String key = 'list',
  }) async {
    final list = readList(box, key: key);
    final index = list.indexWhere(match);
    if (index != -1) {
      list[index] = item;
    } else {
      list.insert(0, item);
    }
    await writeList(box, list, key: key);
  }

  /// 删除匹配的记录
  static Future<void> removeFromList(
    Box box,
    bool Function(Map<String, dynamic> item) match, {
    String key = 'list',
  }) async {
    final list = readList(box, key: key);
    list.removeWhere(match);
    await writeList(box, list, key: key);
  }
}
