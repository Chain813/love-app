import 'package:freezed_annotation/freezed_annotation.dart';

part 'wish.freezed.dart';
part 'wish.g.dart';

/// 心愿模型
@freezed
class Wish with _$Wish {
  const factory Wish({
    @JsonKey(name: 'objectId') required String id,
    @JsonKey(name: 'couple_id') required String coupleId,
    required String title,
    String? description,
    @JsonKey(name: 'is_completed', defaultValue: false) @Default(false) bool isCompleted,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
    @JsonKey(name: 'created_by') required String createdBy,
  }) = _Wish;

  factory Wish.fromJson(Map<String, dynamic> json) => _$WishFromJson(json);

  /// 兼容旧的 fromMap 接口
  factory Wish.fromMap(Map<String, dynamic> map) => Wish.fromJson(map);
}

/// 扩展方法，保持 toMap 兼容
extension WishExtension on Wish {
  Map<String, dynamic> toMap() => toJson();
}
