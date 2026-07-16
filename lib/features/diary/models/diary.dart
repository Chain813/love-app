import 'package:freezed_annotation/freezed_annotation.dart';

part 'diary.freezed.dart';
part 'diary.g.dart';

/// 日记模型
@freezed
class Diary with _$Diary {
  const factory Diary({
    @JsonKey(name: 'objectId') required String objectId,
    @JsonKey(name: 'couple_id') required String coupleId,
    required String content,
    required String mood,
    required String weather,
    @Default(<String>[]) List<String> tags,
    required String date,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'creator_id') required String creatorId,
    required String createdAt,
    required String updatedAt,
  }) = _Diary;

  factory Diary.fromJson(Map<String, dynamic> json) => _$DiaryFromJson(json);
}

extension DiaryExtension on Diary {
  Map<String, dynamic> toMap() => toJson();
}
