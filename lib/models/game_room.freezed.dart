// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_room.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GameRoom _$GameRoomFromJson(Map<String, dynamic> json) {
  return _GameRoom.fromJson(json);
}

/// @nodoc
mixin _$GameRoom {
  @JsonKey(name: 'objectId')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'room_code')
  String get roomCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'couple_id')
  String get coupleId => throw _privateConstructorUsedError;
  @JsonKey(name: 'game_type')
  String get gameType => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'player1_id')
  String get player1Id => throw _privateConstructorUsedError;
  @JsonKey(name: 'player2_id')
  String? get player2Id => throw _privateConstructorUsedError;
  @JsonKey(name: 'player1_ready')
  bool get player1Ready => throw _privateConstructorUsedError;
  @JsonKey(name: 'player2_ready')
  bool get player2Ready => throw _privateConstructorUsedError;
  @JsonKey(name: 'game_data')
  Map<String, dynamic> get gameData => throw _privateConstructorUsedError;
  Map<String, dynamic>? get result => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GameRoomCopyWith<GameRoom> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameRoomCopyWith<$Res> {
  factory $GameRoomCopyWith(GameRoom value, $Res Function(GameRoom) then) =
      _$GameRoomCopyWithImpl<$Res, GameRoom>;
  @useResult
  $Res call(
      {@JsonKey(name: 'objectId') String id,
      @JsonKey(name: 'room_code') String roomCode,
      @JsonKey(name: 'couple_id') String coupleId,
      @JsonKey(name: 'game_type') String gameType,
      String status,
      @JsonKey(name: 'player1_id') String player1Id,
      @JsonKey(name: 'player2_id') String? player2Id,
      @JsonKey(name: 'player1_ready') bool player1Ready,
      @JsonKey(name: 'player2_ready') bool player2Ready,
      @JsonKey(name: 'game_data') Map<String, dynamic> gameData,
      Map<String, dynamic>? result});
}

/// @nodoc
class _$GameRoomCopyWithImpl<$Res, $Val extends GameRoom>
    implements $GameRoomCopyWith<$Res> {
  _$GameRoomCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? roomCode = null,
    Object? coupleId = null,
    Object? gameType = null,
    Object? status = null,
    Object? player1Id = null,
    Object? player2Id = freezed,
    Object? player1Ready = null,
    Object? player2Ready = null,
    Object? gameData = null,
    Object? result = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      roomCode: null == roomCode
          ? _value.roomCode
          : roomCode // ignore: cast_nullable_to_non_nullable
              as String,
      coupleId: null == coupleId
          ? _value.coupleId
          : coupleId // ignore: cast_nullable_to_non_nullable
              as String,
      gameType: null == gameType
          ? _value.gameType
          : gameType // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      player1Id: null == player1Id
          ? _value.player1Id
          : player1Id // ignore: cast_nullable_to_non_nullable
              as String,
      player2Id: freezed == player2Id
          ? _value.player2Id
          : player2Id // ignore: cast_nullable_to_non_nullable
              as String?,
      player1Ready: null == player1Ready
          ? _value.player1Ready
          : player1Ready // ignore: cast_nullable_to_non_nullable
              as bool,
      player2Ready: null == player2Ready
          ? _value.player2Ready
          : player2Ready // ignore: cast_nullable_to_non_nullable
              as bool,
      gameData: null == gameData
          ? _value.gameData
          : gameData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GameRoomImplCopyWith<$Res>
    implements $GameRoomCopyWith<$Res> {
  factory _$$GameRoomImplCopyWith(
          _$GameRoomImpl value, $Res Function(_$GameRoomImpl) then) =
      __$$GameRoomImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'objectId') String id,
      @JsonKey(name: 'room_code') String roomCode,
      @JsonKey(name: 'couple_id') String coupleId,
      @JsonKey(name: 'game_type') String gameType,
      String status,
      @JsonKey(name: 'player1_id') String player1Id,
      @JsonKey(name: 'player2_id') String? player2Id,
      @JsonKey(name: 'player1_ready') bool player1Ready,
      @JsonKey(name: 'player2_ready') bool player2Ready,
      @JsonKey(name: 'game_data') Map<String, dynamic> gameData,
      Map<String, dynamic>? result});
}

/// @nodoc
class __$$GameRoomImplCopyWithImpl<$Res>
    extends _$GameRoomCopyWithImpl<$Res, _$GameRoomImpl>
    implements _$$GameRoomImplCopyWith<$Res> {
  __$$GameRoomImplCopyWithImpl(
      _$GameRoomImpl _value, $Res Function(_$GameRoomImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? roomCode = null,
    Object? coupleId = null,
    Object? gameType = null,
    Object? status = null,
    Object? player1Id = null,
    Object? player2Id = freezed,
    Object? player1Ready = null,
    Object? player2Ready = null,
    Object? gameData = null,
    Object? result = freezed,
  }) {
    return _then(_$GameRoomImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      roomCode: null == roomCode
          ? _value.roomCode
          : roomCode // ignore: cast_nullable_to_non_nullable
              as String,
      coupleId: null == coupleId
          ? _value.coupleId
          : coupleId // ignore: cast_nullable_to_non_nullable
              as String,
      gameType: null == gameType
          ? _value.gameType
          : gameType // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      player1Id: null == player1Id
          ? _value.player1Id
          : player1Id // ignore: cast_nullable_to_non_nullable
              as String,
      player2Id: freezed == player2Id
          ? _value.player2Id
          : player2Id // ignore: cast_nullable_to_non_nullable
              as String?,
      player1Ready: null == player1Ready
          ? _value.player1Ready
          : player1Ready // ignore: cast_nullable_to_non_nullable
              as bool,
      player2Ready: null == player2Ready
          ? _value.player2Ready
          : player2Ready // ignore: cast_nullable_to_non_nullable
              as bool,
      gameData: null == gameData
          ? _value._gameData
          : gameData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      result: freezed == result
          ? _value._result
          : result // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GameRoomImpl implements _GameRoom {
  const _$GameRoomImpl(
      {@JsonKey(name: 'objectId') required this.id,
      @JsonKey(name: 'room_code') required this.roomCode,
      @JsonKey(name: 'couple_id') required this.coupleId,
      @JsonKey(name: 'game_type') required this.gameType,
      this.status = 'waiting',
      @JsonKey(name: 'player1_id') required this.player1Id,
      @JsonKey(name: 'player2_id') this.player2Id,
      @JsonKey(name: 'player1_ready') this.player1Ready = false,
      @JsonKey(name: 'player2_ready') this.player2Ready = false,
      @JsonKey(name: 'game_data')
      final Map<String, dynamic> gameData = const <String, dynamic>{},
      final Map<String, dynamic>? result})
      : _gameData = gameData,
        _result = result;

  factory _$GameRoomImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameRoomImplFromJson(json);

  @override
  @JsonKey(name: 'objectId')
  final String id;
  @override
  @JsonKey(name: 'room_code')
  final String roomCode;
  @override
  @JsonKey(name: 'couple_id')
  final String coupleId;
  @override
  @JsonKey(name: 'game_type')
  final String gameType;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'player1_id')
  final String player1Id;
  @override
  @JsonKey(name: 'player2_id')
  final String? player2Id;
  @override
  @JsonKey(name: 'player1_ready')
  final bool player1Ready;
  @override
  @JsonKey(name: 'player2_ready')
  final bool player2Ready;
  final Map<String, dynamic> _gameData;
  @override
  @JsonKey(name: 'game_data')
  Map<String, dynamic> get gameData {
    if (_gameData is EqualUnmodifiableMapView) return _gameData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_gameData);
  }

  final Map<String, dynamic>? _result;
  @override
  Map<String, dynamic>? get result {
    final value = _result;
    if (value == null) return null;
    if (_result is EqualUnmodifiableMapView) return _result;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'GameRoom(id: $id, roomCode: $roomCode, coupleId: $coupleId, gameType: $gameType, status: $status, player1Id: $player1Id, player2Id: $player2Id, player1Ready: $player1Ready, player2Ready: $player2Ready, gameData: $gameData, result: $result)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameRoomImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.roomCode, roomCode) ||
                other.roomCode == roomCode) &&
            (identical(other.coupleId, coupleId) ||
                other.coupleId == coupleId) &&
            (identical(other.gameType, gameType) ||
                other.gameType == gameType) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.player1Id, player1Id) ||
                other.player1Id == player1Id) &&
            (identical(other.player2Id, player2Id) ||
                other.player2Id == player2Id) &&
            (identical(other.player1Ready, player1Ready) ||
                other.player1Ready == player1Ready) &&
            (identical(other.player2Ready, player2Ready) ||
                other.player2Ready == player2Ready) &&
            const DeepCollectionEquality().equals(other._gameData, _gameData) &&
            const DeepCollectionEquality().equals(other._result, _result));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      roomCode,
      coupleId,
      gameType,
      status,
      player1Id,
      player2Id,
      player1Ready,
      player2Ready,
      const DeepCollectionEquality().hash(_gameData),
      const DeepCollectionEquality().hash(_result));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GameRoomImplCopyWith<_$GameRoomImpl> get copyWith =>
      __$$GameRoomImplCopyWithImpl<_$GameRoomImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameRoomImplToJson(
      this,
    );
  }
}

abstract class _GameRoom implements GameRoom {
  const factory _GameRoom(
      {@JsonKey(name: 'objectId') required final String id,
      @JsonKey(name: 'room_code') required final String roomCode,
      @JsonKey(name: 'couple_id') required final String coupleId,
      @JsonKey(name: 'game_type') required final String gameType,
      final String status,
      @JsonKey(name: 'player1_id') required final String player1Id,
      @JsonKey(name: 'player2_id') final String? player2Id,
      @JsonKey(name: 'player1_ready') final bool player1Ready,
      @JsonKey(name: 'player2_ready') final bool player2Ready,
      @JsonKey(name: 'game_data') final Map<String, dynamic> gameData,
      final Map<String, dynamic>? result}) = _$GameRoomImpl;

  factory _GameRoom.fromJson(Map<String, dynamic> json) =
      _$GameRoomImpl.fromJson;

  @override
  @JsonKey(name: 'objectId')
  String get id;
  @override
  @JsonKey(name: 'room_code')
  String get roomCode;
  @override
  @JsonKey(name: 'couple_id')
  String get coupleId;
  @override
  @JsonKey(name: 'game_type')
  String get gameType;
  @override
  String get status;
  @override
  @JsonKey(name: 'player1_id')
  String get player1Id;
  @override
  @JsonKey(name: 'player2_id')
  String? get player2Id;
  @override
  @JsonKey(name: 'player1_ready')
  bool get player1Ready;
  @override
  @JsonKey(name: 'player2_ready')
  bool get player2Ready;
  @override
  @JsonKey(name: 'game_data')
  Map<String, dynamic> get gameData;
  @override
  Map<String, dynamic>? get result;
  @override
  @JsonKey(ignore: true)
  _$$GameRoomImplCopyWith<_$GameRoomImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
