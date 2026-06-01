// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Diary _$DiaryFromJson(Map<String, dynamic> json) => Diary(
      id: json['objectId'] as String,
      coupleId: json['couple_id'] as String,
      title: json['title'] as String?,
      content: json['content'] as String,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      videoUrl: json['video_url'] as String?,
      weather: json['weather'] as String? ?? '☀️',
      weatherText: json['weather_text'] as String? ?? '晴天',
      mood: json['mood'] as String? ?? '😊',
      moodText: json['mood_text'] as String? ?? '开心',
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      locationName: json['location_name'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      authorId: json['author_id'] as String,
      lastEditorId: json['last_editor_id'] as String?,
      diaryDate: DateTime.parse(json['diary_date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$DiaryToJson(Diary instance) => <String, dynamic>{
      'objectId': instance.id,
      'couple_id': instance.coupleId,
      'title': instance.title,
      'content': instance.content,
      'images': instance.images,
      'video_url': instance.videoUrl,
      'weather': instance.weather,
      'weather_text': instance.weatherText,
      'mood': instance.mood,
      'mood_text': instance.moodText,
      'tags': instance.tags,
      'location_name': instance.locationName,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'author_id': instance.authorId,
      'last_editor_id': instance.lastEditorId,
      'diary_date': instance.diaryDate.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
