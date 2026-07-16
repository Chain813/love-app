// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DiaryImpl _$$DiaryImplFromJson(Map<String, dynamic> json) => _$DiaryImpl(
      objectId: json['objectId'] as String,
      coupleId: json['couple_id'] as String,
      content: json['content'] as String,
      mood: json['mood'] as String,
      weather: json['weather'] as String,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
      date: json['date'] as String,
      imageUrl: json['image_url'] as String?,
      creatorId: json['creator_id'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );

Map<String, dynamic> _$$DiaryImplToJson(_$DiaryImpl instance) =>
    <String, dynamic>{
      'objectId': instance.objectId,
      'couple_id': instance.coupleId,
      'content': instance.content,
      'mood': instance.mood,
      'weather': instance.weather,
      'tags': instance.tags,
      'date': instance.date,
      'image_url': instance.imageUrl,
      'creator_id': instance.creatorId,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
