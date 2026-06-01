// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'anniversary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Anniversary _$AnniversaryFromJson(Map<String, dynamic> json) {
  return _Anniversary.fromJson(json);
}

/// @nodoc
mixin _$Anniversary {
  @JsonKey(name: 'objectId')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'couple_id')
  String get coupleId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_lunar')
  bool get isLunar => throw _privateConstructorUsedError;
  @JsonKey(name: 'remind_days')
  List<int> get remindDays => throw _privateConstructorUsedError;
  String get icon => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AnniversaryCopyWith<Anniversary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnniversaryCopyWith<$Res> {
  factory $AnniversaryCopyWith(
          Anniversary value, $Res Function(Anniversary) then) =
      _$AnniversaryCopyWithImpl<$Res, Anniversary>;
  @useResult
  $Res call(
      {@JsonKey(name: 'objectId') String id,
      @JsonKey(name: 'couple_id') String coupleId,
      String title,
      DateTime date,
      @JsonKey(name: 'is_lunar') bool isLunar,
      @JsonKey(name: 'remind_days') List<int> remindDays,
      String icon});
}

/// @nodoc
class _$AnniversaryCopyWithImpl<$Res, $Val extends Anniversary>
    implements $AnniversaryCopyWith<$Res> {
  _$AnniversaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? coupleId = null,
    Object? title = null,
    Object? date = null,
    Object? isLunar = null,
    Object? remindDays = null,
    Object? icon = null,
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
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isLunar: null == isLunar
          ? _value.isLunar
          : isLunar // ignore: cast_nullable_to_non_nullable
              as bool,
      remindDays: null == remindDays
          ? _value.remindDays
          : remindDays // ignore: cast_nullable_to_non_nullable
              as List<int>,
      icon: null == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AnniversaryImplCopyWith<$Res>
    implements $AnniversaryCopyWith<$Res> {
  factory _$$AnniversaryImplCopyWith(
          _$AnniversaryImpl value, $Res Function(_$AnniversaryImpl) then) =
      __$$AnniversaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'objectId') String id,
      @JsonKey(name: 'couple_id') String coupleId,
      String title,
      DateTime date,
      @JsonKey(name: 'is_lunar') bool isLunar,
      @JsonKey(name: 'remind_days') List<int> remindDays,
      String icon});
}

/// @nodoc
class __$$AnniversaryImplCopyWithImpl<$Res>
    extends _$AnniversaryCopyWithImpl<$Res, _$AnniversaryImpl>
    implements _$$AnniversaryImplCopyWith<$Res> {
  __$$AnniversaryImplCopyWithImpl(
      _$AnniversaryImpl _value, $Res Function(_$AnniversaryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? coupleId = null,
    Object? title = null,
    Object? date = null,
    Object? isLunar = null,
    Object? remindDays = null,
    Object? icon = null,
  }) {
    return _then(_$AnniversaryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      coupleId: null == coupleId
          ? _value.coupleId
          : coupleId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isLunar: null == isLunar
          ? _value.isLunar
          : isLunar // ignore: cast_nullable_to_non_nullable
              as bool,
      remindDays: null == remindDays
          ? _value._remindDays
          : remindDays // ignore: cast_nullable_to_non_nullable
              as List<int>,
      icon: null == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AnniversaryImpl implements _Anniversary {
  const _$AnniversaryImpl(
      {@JsonKey(name: 'objectId') required this.id,
      @JsonKey(name: 'couple_id') required this.coupleId,
      required this.title,
      required this.date,
      @JsonKey(name: 'is_lunar') this.isLunar = false,
      @JsonKey(name: 'remind_days')
      final List<int> remindDays = const [1, 3, 7],
      required this.icon})
      : _remindDays = remindDays;

  factory _$AnniversaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$AnniversaryImplFromJson(json);

  @override
  @JsonKey(name: 'objectId')
  final String id;
  @override
  @JsonKey(name: 'couple_id')
  final String coupleId;
  @override
  final String title;
  @override
  final DateTime date;
  @override
  @JsonKey(name: 'is_lunar')
  final bool isLunar;
  final List<int> _remindDays;
  @override
  @JsonKey(name: 'remind_days')
  List<int> get remindDays {
    if (_remindDays is EqualUnmodifiableListView) return _remindDays;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_remindDays);
  }

  @override
  final String icon;

  @override
  String toString() {
    return 'Anniversary(id: $id, coupleId: $coupleId, title: $title, date: $date, isLunar: $isLunar, remindDays: $remindDays, icon: $icon)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnniversaryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.coupleId, coupleId) ||
                other.coupleId == coupleId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.isLunar, isLunar) || other.isLunar == isLunar) &&
            const DeepCollectionEquality()
                .equals(other._remindDays, _remindDays) &&
            (identical(other.icon, icon) || other.icon == icon));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, coupleId, title, date,
      isLunar, const DeepCollectionEquality().hash(_remindDays), icon);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AnniversaryImplCopyWith<_$AnniversaryImpl> get copyWith =>
      __$$AnniversaryImplCopyWithImpl<_$AnniversaryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AnniversaryImplToJson(
      this,
    );
  }
}

abstract class _Anniversary implements Anniversary {
  const factory _Anniversary(
      {@JsonKey(name: 'objectId') required final String id,
      @JsonKey(name: 'couple_id') required final String coupleId,
      required final String title,
      required final DateTime date,
      @JsonKey(name: 'is_lunar') final bool isLunar,
      @JsonKey(name: 'remind_days') final List<int> remindDays,
      required final String icon}) = _$AnniversaryImpl;

  factory _Anniversary.fromJson(Map<String, dynamic> json) =
      _$AnniversaryImpl.fromJson;

  @override
  @JsonKey(name: 'objectId')
  String get id;
  @override
  @JsonKey(name: 'couple_id')
  String get coupleId;
  @override
  String get title;
  @override
  DateTime get date;
  @override
  @JsonKey(name: 'is_lunar')
  bool get isLunar;
  @override
  @JsonKey(name: 'remind_days')
  List<int> get remindDays;
  @override
  String get icon;
  @override
  @JsonKey(ignore: true)
  _$$AnniversaryImplCopyWith<_$AnniversaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
