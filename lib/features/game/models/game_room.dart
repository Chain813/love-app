import 'package:freezed_annotation/freezed_annotation.dart';

part './game_room.freezed.dart';
part './game_room.g.dart';

/// 游戏房间模型
@freezed
class GameRoom with _$GameRoom {
  const factory GameRoom({
    @JsonKey(name: 'objectId') required String id,
    @JsonKey(name: 'room_code') required String roomCode,
    @JsonKey(name: 'couple_id') required String coupleId,
    @JsonKey(name: 'game_type') required String gameType,
    @Default('waiting') String status,
    @JsonKey(name: 'player1_id') required String player1Id,
    @JsonKey(name: 'player2_id') String? player2Id,
    @JsonKey(name: 'player1_ready') @Default(false) bool player1Ready,
    @JsonKey(name: 'player2_ready') @Default(false) bool player2Ready,
    @JsonKey(name: 'game_data') @Default(<String, dynamic>{}) Map<String, dynamic> gameData,
    Map<String, dynamic>? result,
  }) = _GameRoom;

  factory GameRoom.fromJson(Map<String, dynamic> json) => _$GameRoomFromJson(json);
  factory GameRoom.fromMap(Map<String, dynamic> map) => GameRoom.fromJson(map);
}

extension GameRoomExtension on GameRoom {
  Map<String, dynamic> toMap() => toJson();
  bool get isReady => player1Ready && player2Ready;
  bool get isFull => player2Id != null;
}
