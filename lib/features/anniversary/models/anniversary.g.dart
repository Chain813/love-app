// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anniversary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AnniversaryImpl _$$AnniversaryImplFromJson(Map<String, dynamic> json) =>
    _$AnniversaryImpl(
      id: json['objectId'] as String,
      coupleId: json['couple_id'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      isLunar: json['is_lunar'] as bool? ?? false,
      remindDays: (json['remind_days'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [1, 3, 7],
      icon: json['icon'] as String,
    );

Map<String, dynamic> _$$AnniversaryImplToJson(_$AnniversaryImpl instance) =>
    <String, dynamic>{
      'objectId': instance.id,
      'couple_id': instance.coupleId,
      'title': instance.title,
      'date': instance.date.toIso8601String(),
      'is_lunar': instance.isLunar,
      'remind_days': instance.remindDays,
      'icon': instance.icon,
    };
