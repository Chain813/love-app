import 'package:json_annotation/json_annotation.dart';

part 'diary.g.dart';

/// 日记模型
@JsonSerializable()
class Diary {
  @JsonKey(name: 'objectId')
  final String id;

  @JsonKey(name: 'couple_id')
  final String coupleId;

  final String? title;
  final String content;

  @JsonKey(defaultValue: <String>[])
  final List<String> images;

  @JsonKey(name: 'video_url')
  final String? videoUrl;

  @JsonKey(defaultValue: '☀️')
  final String weather;

  @JsonKey(name: 'weather_text', defaultValue: '晴天')
  final String weatherText;

  @JsonKey(defaultValue: '😊')
  final String mood;

  @JsonKey(name: 'mood_text', defaultValue: '开心')
  final String moodText;

  @JsonKey(defaultValue: <String>[])
  final List<String> tags;

  @JsonKey(name: 'location_name')
  final String? locationName;

  final double? latitude;
  final double? longitude;

  @JsonKey(name: 'author_id')
  final String authorId;

  @JsonKey(name: 'last_editor_id')
  final String? lastEditorId;

  @JsonKey(name: 'diary_date')
  final DateTime diaryDate;

  final DateTime createdAt;
  final DateTime updatedAt;

  Diary({
    required this.id,
    required this.coupleId,
    this.title,
    required this.content,
    this.images = const [],
    this.videoUrl,
    this.weather = '☀️',
    this.weatherText = '晴天',
    this.mood = '😊',
    this.moodText = '开心',
    this.tags = const [],
    this.locationName,
    this.latitude,
    this.longitude,
    required this.authorId,
    this.lastEditorId,
    required this.diaryDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Diary.fromJson(Map<String, dynamic> json) => _$DiaryFromJson(json);
  Map<String, dynamic> toJson() => _$DiaryToJson(this);

  /// 兼容旧的 fromMap/toMap 接口
  factory Diary.fromMap(Map<String, dynamic> map) => Diary.fromJson(map);
  Map<String, dynamic> toMap() => toJson();

  Diary copyWith({
    String? id,
    String? coupleId,
    String? title,
    String? content,
    List<String>? images,
    String? videoUrl,
    String? weather,
    String? weatherText,
    String? mood,
    String? moodText,
    List<String>? tags,
    String? locationName,
    double? latitude,
    double? longitude,
    String? authorId,
    String? lastEditorId,
    DateTime? diaryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Diary(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      title: title ?? this.title,
      content: content ?? this.content,
      images: images ?? this.images,
      videoUrl: videoUrl ?? this.videoUrl,
      weather: weather ?? this.weather,
      weatherText: weatherText ?? this.weatherText,
      mood: mood ?? this.mood,
      moodText: moodText ?? this.moodText,
      tags: tags ?? this.tags,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      authorId: authorId ?? this.authorId,
      lastEditorId: lastEditorId ?? this.lastEditorId,
      diaryDate: diaryDate ?? this.diaryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Diary && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
