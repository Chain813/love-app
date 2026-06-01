// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Diary _$DiaryFromJson(Map<String, dynamic> json) {
  return _Diary.fromJson(json);
}

/// @nodoc
mixin _$Diary {
  @JsonKey(name: 'objectId')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'couple_id')
  String get coupleId => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  List<String> get images => throw _privateConstructorUsedError;
  @JsonKey(name: 'video_url')
  String? get videoUrl => throw _privateConstructorUsedError;
  String get weather => throw _privateConstructorUsedError;
  @JsonKey(name: 'weather_text')
  String get weatherText => throw _privateConstructorUsedError;
  String get mood => throw _privateConstructorUsedError;
  @JsonKey(name: 'mood_text')
  String get moodText => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  @JsonKey(name: 'location_name')
  String? get locationName => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'author_id')
  String get authorId => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_editor_id')
  String? get lastEditorId => throw _privateConstructorUsedError;
  @JsonKey(name: 'diary_date')
  DateTime get diaryDate => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DiaryCopyWith<Diary> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiaryCopyWith<$Res> {
  factory $DiaryCopyWith(Diary value, $Res Function(Diary) then) =
      _$DiaryCopyWithImpl<$Res, Diary>;
  @useResult
  $Res call(
      {@JsonKey(name: 'objectId') String id,
      @JsonKey(name: 'couple_id') String coupleId,
      String? title,
      String content,
      List<String> images,
      @JsonKey(name: 'video_url') String? videoUrl,
      String weather,
      @JsonKey(name: 'weather_text') String weatherText,
      String mood,
      @JsonKey(name: 'mood_text') String moodText,
      List<String> tags,
      @JsonKey(name: 'location_name') String? locationName,
      double? latitude,
      double? longitude,
      @JsonKey(name: 'author_id') String authorId,
      @JsonKey(name: 'last_editor_id') String? lastEditorId,
      @JsonKey(name: 'diary_date') DateTime diaryDate,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$DiaryCopyWithImpl<$Res, $Val extends Diary>
    implements $DiaryCopyWith<$Res> {
  _$DiaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? coupleId = null,
    Object? title = freezed,
    Object? content = null,
    Object? images = null,
    Object? videoUrl = freezed,
    Object? weather = null,
    Object? weatherText = null,
    Object? mood = null,
    Object? moodText = null,
    Object? tags = null,
    Object? locationName = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? authorId = null,
    Object? lastEditorId = freezed,
    Object? diaryDate = null,
    Object? createdAt = null,
    Object? updatedAt = null,
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
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      images: null == images
          ? _value.images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      videoUrl: freezed == videoUrl
          ? _value.videoUrl
          : videoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      weather: null == weather
          ? _value.weather
          : weather // ignore: cast_nullable_to_non_nullable
              as String,
      weatherText: null == weatherText
          ? _value.weatherText
          : weatherText // ignore: cast_nullable_to_non_nullable
              as String,
      mood: null == mood
          ? _value.mood
          : mood // ignore: cast_nullable_to_non_nullable
              as String,
      moodText: null == moodText
          ? _value.moodText
          : moodText // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      locationName: freezed == locationName
          ? _value.locationName
          : locationName // ignore: cast_nullable_to_non_nullable
              as String?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      authorId: null == authorId
          ? _value.authorId
          : authorId // ignore: cast_nullable_to_non_nullable
              as String,
      lastEditorId: freezed == lastEditorId
          ? _value.lastEditorId
          : lastEditorId // ignore: cast_nullable_to_non_nullable
              as String?,
      diaryDate: null == diaryDate
          ? _value.diaryDate
          : diaryDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DiaryImplCopyWith<$Res> implements $DiaryCopyWith<$Res> {
  factory _$$DiaryImplCopyWith(
          _$DiaryImpl value, $Res Function(_$DiaryImpl) then) =
      __$$DiaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'objectId') String id,
      @JsonKey(name: 'couple_id') String coupleId,
      String? title,
      String content,
      List<String> images,
      @JsonKey(name: 'video_url') String? videoUrl,
      String weather,
      @JsonKey(name: 'weather_text') String weatherText,
      String mood,
      @JsonKey(name: 'mood_text') String moodText,
      List<String> tags,
      @JsonKey(name: 'location_name') String? locationName,
      double? latitude,
      double? longitude,
      @JsonKey(name: 'author_id') String authorId,
      @JsonKey(name: 'last_editor_id') String? lastEditorId,
      @JsonKey(name: 'diary_date') DateTime diaryDate,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$DiaryImplCopyWithImpl<$Res>
    extends _$DiaryCopyWithImpl<$Res, _$DiaryImpl>
    implements _$$DiaryImplCopyWith<$Res> {
  __$$DiaryImplCopyWithImpl(
      _$DiaryImpl _value, $Res Function(_$DiaryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? coupleId = null,
    Object? title = freezed,
    Object? content = null,
    Object? images = null,
    Object? videoUrl = freezed,
    Object? weather = null,
    Object? weatherText = null,
    Object? mood = null,
    Object? moodText = null,
    Object? tags = null,
    Object? locationName = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? authorId = null,
    Object? lastEditorId = freezed,
    Object? diaryDate = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$DiaryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      coupleId: null == coupleId
          ? _value.coupleId
          : coupleId // ignore: cast_nullable_to_non_nullable
              as String,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      images: null == images
          ? _value._images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      videoUrl: freezed == videoUrl
          ? _value.videoUrl
          : videoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      weather: null == weather
          ? _value.weather
          : weather // ignore: cast_nullable_to_non_nullable
              as String,
      weatherText: null == weatherText
          ? _value.weatherText
          : weatherText // ignore: cast_nullable_to_non_nullable
              as String,
      mood: null == mood
          ? _value.mood
          : mood // ignore: cast_nullable_to_non_nullable
              as String,
      moodText: null == moodText
          ? _value.moodText
          : moodText // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      locationName: freezed == locationName
          ? _value.locationName
          : locationName // ignore: cast_nullable_to_non_nullable
              as String?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      authorId: null == authorId
          ? _value.authorId
          : authorId // ignore: cast_nullable_to_non_nullable
              as String,
      lastEditorId: freezed == lastEditorId
          ? _value.lastEditorId
          : lastEditorId // ignore: cast_nullable_to_non_nullable
              as String?,
      diaryDate: null == diaryDate
          ? _value.diaryDate
          : diaryDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DiaryImpl implements _Diary {
  const _$DiaryImpl(
      {@JsonKey(name: 'objectId') required this.id,
      @JsonKey(name: 'couple_id') required this.coupleId,
      this.title,
      required this.content,
      final List<String> images = const <String>[],
      @JsonKey(name: 'video_url') this.videoUrl,
      this.weather = '☀️',
      @JsonKey(name: 'weather_text') this.weatherText = '晴天',
      this.mood = '😊',
      @JsonKey(name: 'mood_text') this.moodText = '开心',
      final List<String> tags = const <String>[],
      @JsonKey(name: 'location_name') this.locationName,
      this.latitude,
      this.longitude,
      @JsonKey(name: 'author_id') required this.authorId,
      @JsonKey(name: 'last_editor_id') this.lastEditorId,
      @JsonKey(name: 'diary_date') required this.diaryDate,
      required this.createdAt,
      required this.updatedAt})
      : _images = images,
        _tags = tags;

  factory _$DiaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiaryImplFromJson(json);

  @override
  @JsonKey(name: 'objectId')
  final String id;
  @override
  @JsonKey(name: 'couple_id')
  final String coupleId;
  @override
  final String? title;
  @override
  final String content;
  final List<String> _images;
  @override
  @JsonKey()
  List<String> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  @override
  @JsonKey(name: 'video_url')
  final String? videoUrl;
  @override
  @JsonKey()
  final String weather;
  @override
  @JsonKey(name: 'weather_text')
  final String weatherText;
  @override
  @JsonKey()
  final String mood;
  @override
  @JsonKey(name: 'mood_text')
  final String moodText;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey(name: 'location_name')
  final String? locationName;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  @JsonKey(name: 'author_id')
  final String authorId;
  @override
  @JsonKey(name: 'last_editor_id')
  final String? lastEditorId;
  @override
  @JsonKey(name: 'diary_date')
  final DateTime diaryDate;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Diary(id: $id, coupleId: $coupleId, title: $title, content: $content, images: $images, videoUrl: $videoUrl, weather: $weather, weatherText: $weatherText, mood: $mood, moodText: $moodText, tags: $tags, locationName: $locationName, latitude: $latitude, longitude: $longitude, authorId: $authorId, lastEditorId: $lastEditorId, diaryDate: $diaryDate, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiaryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.coupleId, coupleId) ||
                other.coupleId == coupleId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.content, content) || other.content == content) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            (identical(other.videoUrl, videoUrl) ||
                other.videoUrl == videoUrl) &&
            (identical(other.weather, weather) || other.weather == weather) &&
            (identical(other.weatherText, weatherText) ||
                other.weatherText == weatherText) &&
            (identical(other.mood, mood) || other.mood == mood) &&
            (identical(other.moodText, moodText) ||
                other.moodText == moodText) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.locationName, locationName) ||
                other.locationName == locationName) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.lastEditorId, lastEditorId) ||
                other.lastEditorId == lastEditorId) &&
            (identical(other.diaryDate, diaryDate) ||
                other.diaryDate == diaryDate) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        coupleId,
        title,
        content,
        const DeepCollectionEquality().hash(_images),
        videoUrl,
        weather,
        weatherText,
        mood,
        moodText,
        const DeepCollectionEquality().hash(_tags),
        locationName,
        latitude,
        longitude,
        authorId,
        lastEditorId,
        diaryDate,
        createdAt,
        updatedAt
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DiaryImplCopyWith<_$DiaryImpl> get copyWith =>
      __$$DiaryImplCopyWithImpl<_$DiaryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DiaryImplToJson(
      this,
    );
  }
}

abstract class _Diary implements Diary {
  const factory _Diary(
      {@JsonKey(name: 'objectId') required final String id,
      @JsonKey(name: 'couple_id') required final String coupleId,
      final String? title,
      required final String content,
      final List<String> images,
      @JsonKey(name: 'video_url') final String? videoUrl,
      final String weather,
      @JsonKey(name: 'weather_text') final String weatherText,
      final String mood,
      @JsonKey(name: 'mood_text') final String moodText,
      final List<String> tags,
      @JsonKey(name: 'location_name') final String? locationName,
      final double? latitude,
      final double? longitude,
      @JsonKey(name: 'author_id') required final String authorId,
      @JsonKey(name: 'last_editor_id') final String? lastEditorId,
      @JsonKey(name: 'diary_date') required final DateTime diaryDate,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$DiaryImpl;

  factory _Diary.fromJson(Map<String, dynamic> json) = _$DiaryImpl.fromJson;

  @override
  @JsonKey(name: 'objectId')
  String get id;
  @override
  @JsonKey(name: 'couple_id')
  String get coupleId;
  @override
  String? get title;
  @override
  String get content;
  @override
  List<String> get images;
  @override
  @JsonKey(name: 'video_url')
  String? get videoUrl;
  @override
  String get weather;
  @override
  @JsonKey(name: 'weather_text')
  String get weatherText;
  @override
  String get mood;
  @override
  @JsonKey(name: 'mood_text')
  String get moodText;
  @override
  List<String> get tags;
  @override
  @JsonKey(name: 'location_name')
  String? get locationName;
  @override
  double? get latitude;
  @override
  double? get longitude;
  @override
  @JsonKey(name: 'author_id')
  String get authorId;
  @override
  @JsonKey(name: 'last_editor_id')
  String? get lastEditorId;
  @override
  @JsonKey(name: 'diary_date')
  DateTime get diaryDate;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$DiaryImplCopyWith<_$DiaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
