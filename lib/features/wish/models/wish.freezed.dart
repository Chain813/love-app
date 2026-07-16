// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wish.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Wish _$WishFromJson(Map<String, dynamic> json) {
  return _Wish.fromJson(json);
}

/// @nodoc
mixin _$Wish {
  @JsonKey(name: 'objectId')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'couple_id')
  String get coupleId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_completed', defaultValue: false)
  bool get isCompleted => throw _privateConstructorUsedError;
  @JsonKey(name: 'completed_at')
  DateTime? get completedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_by')
  String get createdBy => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WishCopyWith<Wish> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WishCopyWith<$Res> {
  factory $WishCopyWith(Wish value, $Res Function(Wish) then) =
      _$WishCopyWithImpl<$Res, Wish>;
  @useResult
  $Res call(
      {@JsonKey(name: 'objectId') String id,
      @JsonKey(name: 'couple_id') String coupleId,
      String title,
      String? description,
      @JsonKey(name: 'is_completed', defaultValue: false) bool isCompleted,
      @JsonKey(name: 'completed_at') DateTime? completedAt,
      @JsonKey(name: 'created_by') String createdBy});
}

/// @nodoc
class _$WishCopyWithImpl<$Res, $Val extends Wish>
    implements $WishCopyWith<$Res> {
  _$WishCopyWithImpl(this._value, this._then);

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
    Object? description = freezed,
    Object? isCompleted = null,
    Object? completedAt = freezed,
    Object? createdBy = null,
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
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WishImplCopyWith<$Res> implements $WishCopyWith<$Res> {
  factory _$$WishImplCopyWith(
          _$WishImpl value, $Res Function(_$WishImpl) then) =
      __$$WishImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'objectId') String id,
      @JsonKey(name: 'couple_id') String coupleId,
      String title,
      String? description,
      @JsonKey(name: 'is_completed', defaultValue: false) bool isCompleted,
      @JsonKey(name: 'completed_at') DateTime? completedAt,
      @JsonKey(name: 'created_by') String createdBy});
}

/// @nodoc
class __$$WishImplCopyWithImpl<$Res>
    extends _$WishCopyWithImpl<$Res, _$WishImpl>
    implements _$$WishImplCopyWith<$Res> {
  __$$WishImplCopyWithImpl(_$WishImpl _value, $Res Function(_$WishImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? coupleId = null,
    Object? title = null,
    Object? description = freezed,
    Object? isCompleted = null,
    Object? completedAt = freezed,
    Object? createdBy = null,
  }) {
    return _then(_$WishImpl(
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
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WishImpl implements _Wish {
  const _$WishImpl(
      {@JsonKey(name: 'objectId') required this.id,
      @JsonKey(name: 'couple_id') required this.coupleId,
      required this.title,
      this.description,
      @JsonKey(name: 'is_completed', defaultValue: false)
      this.isCompleted = false,
      @JsonKey(name: 'completed_at') this.completedAt,
      @JsonKey(name: 'created_by') required this.createdBy});

  factory _$WishImpl.fromJson(Map<String, dynamic> json) =>
      _$$WishImplFromJson(json);

  @override
  @JsonKey(name: 'objectId')
  final String id;
  @override
  @JsonKey(name: 'couple_id')
  final String coupleId;
  @override
  final String title;
  @override
  final String? description;
  @override
  @JsonKey(name: 'is_completed', defaultValue: false)
  final bool isCompleted;
  @override
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  @override
  @JsonKey(name: 'created_by')
  final String createdBy;

  @override
  String toString() {
    return 'Wish(id: $id, coupleId: $coupleId, title: $title, description: $description, isCompleted: $isCompleted, completedAt: $completedAt, createdBy: $createdBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WishImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.coupleId, coupleId) ||
                other.coupleId == coupleId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, coupleId, title, description,
      isCompleted, completedAt, createdBy);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WishImplCopyWith<_$WishImpl> get copyWith =>
      __$$WishImplCopyWithImpl<_$WishImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WishImplToJson(
      this,
    );
  }
}

abstract class _Wish implements Wish {
  const factory _Wish(
          {@JsonKey(name: 'objectId') required final String id,
          @JsonKey(name: 'couple_id') required final String coupleId,
          required final String title,
          final String? description,
          @JsonKey(name: 'is_completed', defaultValue: false)
          final bool isCompleted,
          @JsonKey(name: 'completed_at') final DateTime? completedAt,
          @JsonKey(name: 'created_by') required final String createdBy}) =
      _$WishImpl;

  factory _Wish.fromJson(Map<String, dynamic> json) = _$WishImpl.fromJson;

  @override
  @JsonKey(name: 'objectId')
  String get id;
  @override
  @JsonKey(name: 'couple_id')
  String get coupleId;
  @override
  String get title;
  @override
  String? get description;
  @override
  @JsonKey(name: 'is_completed', defaultValue: false)
  bool get isCompleted;
  @override
  @JsonKey(name: 'completed_at')
  DateTime? get completedAt;
  @override
  @JsonKey(name: 'created_by')
  String get createdBy;
  @override
  @JsonKey(ignore: true)
  _$$WishImplCopyWith<_$WishImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
