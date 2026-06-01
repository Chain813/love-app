import 'package:json_annotation/json_annotation.dart';

part 'game_room.g.dart';

/// 游戏房间模型
@JsonSerializable()
class GameRoom {
  @JsonKey(name: 'objectId')
  final String id;

  @JsonKey(name: 'room_code')
  final String roomCode;

  @JsonKey(name: 'couple_id')
  final String coupleId;

  @JsonKey(name: 'game_type')
  final String gameType;

  @JsonKey(defaultValue: 'waiting')
  final String status;

  @JsonKey(name: 'player1_id')
  final String player1Id;

  @JsonKey(name: 'player2_id')
  final String? player2Id;

  @JsonKey(name: 'player1_ready', defaultValue: false)
  final bool player1Ready;

  @JsonKey(name: 'player2_ready', defaultValue: false)
  final bool player2Ready;

  @JsonKey(name: 'game_data', defaultValue: <String, dynamic>{})
  final Map<String, dynamic> gameData;

  final Map<String, dynamic>? result;

  GameRoom({
    required this.id,
    required this.roomCode,
    required this.coupleId,
    required this.gameType,
    this.status = 'waiting',
    required this.player1Id,
    this.player2Id,
    this.player1Ready = false,
    this.player2Ready = false,
    this.gameData = const {},
    this.result,
  });

  factory GameRoom.fromJson(Map<String, dynamic> json) => _$GameRoomFromJson(json);
  Map<String, dynamic> toJson() => _$GameRoomToJson(this);

  /// 兼容旧的 fromMap/toMap 接口
  factory GameRoom.fromMap(Map<String, dynamic> map) => GameRoom.fromJson(map);
  Map<String, dynamic> toMap() => toJson();

  GameRoom copyWith({
    String? id,
    String? roomCode,
    String? coupleId,
    String? gameType,
    String? status,
    String? player1Id,
    String? player2Id,
    bool? player1Ready,
    bool? player2Ready,
    Map<String, dynamic>? gameData,
    Map<String, dynamic>? result,
  }) {
    return GameRoom(
      id: id ?? this.id,
      roomCode: roomCode ?? this.roomCode,
      coupleId: coupleId ?? this.coupleId,
      gameType: gameType ?? this.gameType,
      status: status ?? this.status,
      player1Id: player1Id ?? this.player1Id,
      player2Id: player2Id ?? this.player2Id,
      player1Ready: player1Ready ?? this.player1Ready,
      player2Ready: player2Ready ?? this.player2Ready,
      gameData: gameData ?? this.gameData,
      result: result ?? this.result,
    );
  }

  bool get isReady => player1Ready && player2Ready;
  bool get isFull => player2Id != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameRoom && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
