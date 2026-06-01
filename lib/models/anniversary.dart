import 'package:json_annotation/json_annotation.dart';

part 'anniversary.g.dart';

/// 纪念日模型
@JsonSerializable()
class Anniversary {
  @JsonKey(name: 'objectId')
  final String id;

  @JsonKey(name: 'couple_id')
  final String coupleId;

  final String title;
  final DateTime date;

  @JsonKey(name: 'is_lunar', defaultValue: false)
  final bool isLunar;

  @JsonKey(name: 'remind_days', defaultValue: [1, 3, 7])
  final List<int> remindDays;

  final String icon;

  Anniversary({
    required this.id,
    required this.coupleId,
    required this.title,
    required this.date,
    this.isLunar = false,
    this.remindDays = const [1, 3, 7],
    required this.icon,
  });

  factory Anniversary.fromJson(Map<String, dynamic> json) => _$AnniversaryFromJson(json);
  Map<String, dynamic> toJson() => _$AnniversaryToJson(this);

  /// 兼容旧的 fromMap/toMap 接口
  factory Anniversary.fromMap(Map<String, dynamic> map) => Anniversary.fromJson(map);
  Map<String, dynamic> toMap() => toJson();

  Anniversary copyWith({
    String? id,
    String? coupleId,
    String? title,
    DateTime? date,
    bool? isLunar,
    List<int>? remindDays,
    String? icon,
  }) {
    return Anniversary(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      title: title ?? this.title,
      date: date ?? this.date,
      isLunar: isLunar ?? this.isLunar,
      remindDays: remindDays ?? this.remindDays,
      icon: icon ?? this.icon,
    );
  }

  /// 距离下一个纪念日的天数
  int get daysUntilNext {
    final now = DateTime.now();
    var nextDate = DateTime(now.year, date.month, date.day);
    if (nextDate.isBefore(now)) {
      nextDate = DateTime(now.year + 1, date.month, date.day);
    }
    return nextDate.difference(now).inDays;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Anniversary && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
