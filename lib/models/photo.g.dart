// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Photo _$PhotoFromJson(Map<String, dynamic> json) => Photo(
      id: json['objectId'] as String,
      coupleId: json['couple_id'] as String,
      imageUrl: json['image_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationName: json['location_name'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      takenAt: DateTime.parse(json['taken_at'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      diaryId: json['diary_id'] as String?,
    );

Map<String, dynamic> _$PhotoToJson(Photo instance) => <String, dynamic>{
      'objectId': instance.id,
      'couple_id': instance.coupleId,
      'image_url': instance.imageUrl,
      'thumbnail_url': instance.thumbnailUrl,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'location_name': instance.locationName,
      'tags': instance.tags,
      'taken_at': instance.takenAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'diary_id': instance.diaryId,
    };
