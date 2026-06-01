import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo.freezed.dart';
part 'photo.g.dart';

/// 照片模型
@freezed
class Photo with _$Photo {
  const factory Photo({
    @JsonKey(name: 'objectId') required String id,
    @JsonKey(name: 'couple_id') required String coupleId,
    @JsonKey(name: 'image_url') required String imageUrl,
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
    double? latitude,
    double? longitude,
    @JsonKey(name: 'location_name') String? locationName,
    @Default(<String>[]) List<String> tags,
    @JsonKey(name: 'taken_at') required DateTime takenAt,
    required DateTime createdAt,
    @JsonKey(name: 'diary_id') String? diaryId,
  }) = _Photo;

  factory Photo.fromJson(Map<String, dynamic> json) => _$PhotoFromJson(json);
  factory Photo.fromMap(Map<String, dynamic> map) => Photo.fromJson(map);
}

extension PhotoExtension on Photo {
  Map<String, dynamic> toMap() => toJson();
}
