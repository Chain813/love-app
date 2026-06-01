import 'package:json_annotation/json_annotation.dart';

part 'photo.g.dart';

/// 照片模型
@JsonSerializable()
class Photo {
  @JsonKey(name: 'objectId')
  final String id;

  @JsonKey(name: 'couple_id')
  final String coupleId;

  @JsonKey(name: 'image_url')
  final String imageUrl;

  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;

  final double? latitude;
  final double? longitude;

  @JsonKey(name: 'location_name')
  final String? locationName;

  @JsonKey(defaultValue: <String>[])
  final List<String> tags;

  @JsonKey(name: 'taken_at')
  final DateTime takenAt;

  final DateTime createdAt;

  @JsonKey(name: 'diary_id')
  final String? diaryId;

  Photo({
    required this.id,
    required this.coupleId,
    required this.imageUrl,
    this.thumbnailUrl,
    this.latitude,
    this.longitude,
    this.locationName,
    this.tags = const [],
    required this.takenAt,
    required this.createdAt,
    this.diaryId,
  });

  factory Photo.fromJson(Map<String, dynamic> json) => _$PhotoFromJson(json);
  Map<String, dynamic> toJson() => _$PhotoToJson(this);

  /// 兼容旧的 fromMap/toMap 接口
  factory Photo.fromMap(Map<String, dynamic> map) => Photo.fromJson(map);
  Map<String, dynamic> toMap() => toJson();

  Photo copyWith({
    String? id,
    String? coupleId,
    String? imageUrl,
    String? thumbnailUrl,
    double? latitude,
    double? longitude,
    String? locationName,
    List<String>? tags,
    DateTime? takenAt,
    DateTime? createdAt,
    String? diaryId,
  }) {
    return Photo(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      tags: tags ?? this.tags,
      takenAt: takenAt ?? this.takenAt,
      createdAt: createdAt ?? this.createdAt,
      diaryId: diaryId ?? this.diaryId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Photo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
