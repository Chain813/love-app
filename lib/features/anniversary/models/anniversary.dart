import 'package:freezed_annotation/freezed_annotation.dart';

part 'anniversary.freezed.dart';
part 'anniversary.g.dart';

/// 纪念日模型
@freezed
class Anniversary with _$Anniversary {
  const factory Anniversary({
    @JsonKey(name: 'objectId') required String id,
    @JsonKey(name: 'couple_id') required String coupleId,
    required String title,
    required DateTime date,
    @JsonKey(name: 'is_lunar') @Default(false) bool isLunar,
    @JsonKey(name: 'remind_days') @Default([1, 3, 7]) List<int> remindDays,
    required String icon,
  }) = _Anniversary;

  factory Anniversary.fromJson(Map<String, dynamic> json) => _$AnniversaryFromJson(json);
  factory Anniversary.fromMap(Map<String, dynamic> map) => Anniversary.fromJson(map);
}

extension AnniversaryExtension on Anniversary {
  Map<String, dynamic> toMap() => toJson();

  /// 距离下一个纪念日的天数
  int get daysUntilNext {
    final now = DateTime.now();
    var nextDate = DateTime(now.year, date.month, date.day);
    if (nextDate.isBefore(now)) {
      nextDate = DateTime(now.year + 1, date.month, date.day);
    }
    return nextDate.difference(now).inDays;
  }
}
