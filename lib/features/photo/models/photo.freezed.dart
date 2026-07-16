// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'photo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Photo _$PhotoFromJson(Map<String, dynamic> json) {
  return _Photo.fromJson(json);
}

/// @nodoc
mixin _$Photo {
  @JsonKey(name: 'objectId')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'couple_id')
  String get coupleId => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String get imageUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'thumbnail_url')
  String? get thumbnailUrl => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'location_name')
  String? get locationName => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  @JsonKey(name: 'taken_at')
  DateTime get takenAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'diary_id')
  String? get diaryId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PhotoCopyWith<Photo> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PhotoCopyWith<$Res> {
  factory $PhotoCopyWith(Photo value, $Res Function(Photo) then) =
      _$PhotoCopyWithImpl<$Res, Photo>;
  @useResult
  $Res call(
      {@JsonKey(name: 'objectId') String id,
      @JsonKey(name: 'couple_id') String coupleId,
      @JsonKey(name: 'image_url') String imageUrl,
      @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
      double? latitude,
      double? longitude,
      @JsonKey(name: 'location_name') String? locationName,
      List<String> tags,
      @JsonKey(name: 'taken_at') DateTime takenAt,
      DateTime createdAt,
      @JsonKey(name: 'diary_id') String? diaryId});
}

/// @nodoc
class _$PhotoCopyWithImpl<$Res, $Val extends Photo>
    implements $PhotoCopyWith<$Res> {
  _$PhotoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? coupleId = null,
    Object? imageUrl = null,
    Object? thumbnailUrl = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? locationName = freezed,
    Object? tags = null,
    Object? takenAt = null,
    Object? createdAt = null,
    Object? diaryId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      coupleId: null == coupleId
          ? _value.coupleId
          : coupleId // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      locationName: freezed == locationName
          ? _value.locationName
          : locationName // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      takenAt: null == takenAt
          ? _value.takenAt
          : takenAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      diaryId: freezed == diaryId
          ? _value.diaryId
          : diaryId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PhotoImplCopyWith<$Res> implements $PhotoCopyWith<$Res> {
  factory _$$PhotoImplCopyWith(
          _$PhotoImpl value, $Res Function(_$PhotoImpl) then) =
      __$$PhotoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'objectId') String id,
      @JsonKey(name: 'couple_id') String coupleId,
      @JsonKey(name: 'image_url') String imageUrl,
      @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
      double? latitude,
      double? longitude,
      @JsonKey(name: 'location_name') String? locationName,
      List<String> tags,
      @JsonKey(name: 'taken_at') DateTime takenAt,
      DateTime createdAt,
      @JsonKey(name: 'diary_id') String? diaryId});
}

/// @nodoc
class __$$PhotoImplCopyWithImpl<$Res>
    extends _$PhotoCopyWithImpl<$Res, _$PhotoImpl>
    implements _$$PhotoImplCopyWith<$Res> {
  __$$PhotoImplCopyWithImpl(
      _$PhotoImpl _value, $Res Function(_$PhotoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? coupleId = null,
    Object? imageUrl = null,
    Object? thumbnailUrl = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? locationName = freezed,
    Object? tags = null,
    Object? takenAt = null,
    Object? createdAt = null,
    Object? diaryId = freezed,
  }) {
    return _then(_$PhotoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      coupleId: null == coupleId
          ? _value.coupleId
          : coupleId // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      locationName: freezed == locationName
          ? _value.locationName
          : locationName // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      takenAt: null == takenAt
          ? _value.takenAt
          : takenAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      diaryId: freezed == diaryId
          ? _value.diaryId
          : diaryId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PhotoImpl implements _Photo {
  const _$PhotoImpl(
      {@JsonKey(name: 'objectId') required this.id,
      @JsonKey(name: 'couple_id') required this.coupleId,
      @JsonKey(name: 'image_url') required this.imageUrl,
      @JsonKey(name: 'thumbnail_url') this.thumbnailUrl,
      this.latitude,
      this.longitude,
      @JsonKey(name: 'location_name') this.locationName,
      final List<String> tags = const <String>[],
      @JsonKey(name: 'taken_at') required this.takenAt,
      required this.createdAt,
      @JsonKey(name: 'diary_id') this.diaryId})
      : _tags = tags;

  factory _$PhotoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PhotoImplFromJson(json);

  @override
  @JsonKey(name: 'objectId')
  final String id;
  @override
  @JsonKey(name: 'couple_id')
  final String coupleId;
  @override
  @JsonKey(name: 'image_url')
  final String imageUrl;
  @override
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  @JsonKey(name: 'location_name')
  final String? locationName;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey(name: 'taken_at')
  final DateTime takenAt;
  @override
  final DateTime createdAt;
  @override
  @JsonKey(name: 'diary_id')
  final String? diaryId;

  @override
  String toString() {
    return 'Photo(id: $id, coupleId: $coupleId, imageUrl: $imageUrl, thumbnailUrl: $thumbnailUrl, latitude: $latitude, longitude: $longitude, locationName: $locationName, tags: $tags, takenAt: $takenAt, createdAt: $createdAt, diaryId: $diaryId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PhotoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.coupleId, coupleId) ||
                other.coupleId == coupleId) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.locationName, locationName) ||
                other.locationName == locationName) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.takenAt, takenAt) || other.takenAt == takenAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.diaryId, diaryId) || other.diaryId == diaryId));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      coupleId,
      imageUrl,
      thumbnailUrl,
      latitude,
      longitude,
      locationName,
      const DeepCollectionEquality().hash(_tags),
      takenAt,
      createdAt,
      diaryId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PhotoImplCopyWith<_$PhotoImpl> get copyWith =>
      __$$PhotoImplCopyWithImpl<_$PhotoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PhotoImplToJson(
      this,
    );
  }
}

abstract class _Photo implements Photo {
  const factory _Photo(
      {@JsonKey(name: 'objectId') required final String id,
      @JsonKey(name: 'couple_id') required final String coupleId,
      @JsonKey(name: 'image_url') required final String imageUrl,
      @JsonKey(name: 'thumbnail_url') final String? thumbnailUrl,
      final double? latitude,
      final double? longitude,
      @JsonKey(name: 'location_name') final String? locationName,
      final List<String> tags,
      @JsonKey(name: 'taken_at') required final DateTime takenAt,
      required final DateTime createdAt,
      @JsonKey(name: 'diary_id') final String? diaryId}) = _$PhotoImpl;

  factory _Photo.fromJson(Map<String, dynamic> json) = _$PhotoImpl.fromJson;

  @override
  @JsonKey(name: 'objectId')
  String get id;
  @override
  @JsonKey(name: 'couple_id')
  String get coupleId;
  @override
  @JsonKey(name: 'image_url')
  String get imageUrl;
  @override
  @JsonKey(name: 'thumbnail_url')
  String? get thumbnailUrl;
  @override
  double? get latitude;
  @override
  double? get longitude;
  @override
  @JsonKey(name: 'location_name')
  String? get locationName;
  @override
  List<String> get tags;
  @override
  @JsonKey(name: 'taken_at')
  DateTime get takenAt;
  @override
  DateTime get createdAt;
  @override
  @JsonKey(name: 'diary_id')
  String? get diaryId;
  @override
  @JsonKey(ignore: true)
  _$$PhotoImplCopyWith<_$PhotoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
