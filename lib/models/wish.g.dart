// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wish.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Wish _$WishFromJson(Map<String, dynamic> json) => Wish(
      id: json['objectId'] as String,
      coupleId: json['couple_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      createdBy: json['created_by'] as String,
    );

Map<String, dynamic> _$WishToJson(Wish instance) => <String, dynamic>{
      'objectId': instance.id,
      'couple_id': instance.coupleId,
      'title': instance.title,
      'description': instance.description,
      'is_completed': instance.isCompleted,
      'completed_at': instance.completedAt?.toIso8601String(),
      'created_by': instance.createdBy,
    };
