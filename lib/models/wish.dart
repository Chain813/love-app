import 'package:json_annotation/json_annotation.dart';

part 'wish.g.dart';

/// 心愿模型
@JsonSerializable()
class Wish {
  @JsonKey(name: 'objectId')
  final String id;

  @JsonKey(name: 'couple_id')
  final String coupleId;

  final String title;
  final String? description;

  @JsonKey(name: 'is_completed', defaultValue: false)
  final bool isCompleted;

  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;

  @JsonKey(name: 'created_by')
  final String createdBy;

  Wish({
    required this.id,
    required this.coupleId,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.completedAt,
    required this.createdBy,
  });

  factory Wish.fromJson(Map<String, dynamic> json) => _$WishFromJson(json);
  Map<String, dynamic> toJson() => _$WishToJson(this);

  /// 兼容旧的 fromMap/toMap 接口
  factory Wish.fromMap(Map<String, dynamic> map) => Wish.fromJson(map);
  Map<String, dynamic> toMap() => toJson();

  Wish copyWith({
    String? id,
    String? coupleId,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? completedAt,
    String? createdBy,
  }) {
    return Wish(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wish && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
