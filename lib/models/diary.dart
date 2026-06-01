import 'package:freezed_annotation/freezed_annotation.dart';

part 'diary.freezed.dart';
part 'diary.g.dart';

/// 日记模型
@freezed
class Diary with _$Diary {
  const factory Diary({
    @JsonKey(name: 'objectId') required String id,
    @JsonKey(name: 'couple_id') required String coupleId,
    String? title,
    required String content,
    @Default(<String>[]) List<String> images,
    @JsonKey(name: 'video_url') String? videoUrl,
    @Default('☀️') String weather,
    @JsonKey(name: 'weather_text') @Default('晴天') String weatherText,
    @Default('😊') String mood,
    @JsonKey(name: 'mood_text') @Default('开心') String moodText,
    @Default(<String>[]) List<String> tags,
    @JsonKey(name: 'location_name') String? locationName,
    double? latitude,
    double? longitude,
    @JsonKey(name: 'author_id') required String authorId,
    @JsonKey(name: 'last_editor_id') String? lastEditorId,
    @JsonKey(name: 'diary_date') required DateTime diaryDate,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Diary;

  factory Diary.fromJson(Map<String, dynamic> json) => _$DiaryFromJson(json);
  factory Diary.fromMap(Map<String, dynamic> map) => Diary.fromJson(map);
}

extension DiaryExtension on Diary {
  Map<String, dynamic> toMap() => toJson();
}
