// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameRoom _$GameRoomFromJson(Map<String, dynamic> json) => GameRoom(
      id: json['objectId'] as String,
      roomCode: json['room_code'] as String,
      coupleId: json['couple_id'] as String,
      gameType: json['game_type'] as String,
      status: json['status'] as String? ?? 'waiting',
      player1Id: json['player1_id'] as String,
      player2Id: json['player2_id'] as String?,
      player1Ready: json['player1_ready'] as bool? ?? false,
      player2Ready: json['player2_ready'] as bool? ?? false,
      gameData: json['game_data'] as Map<String, dynamic>? ?? {},
      result: json['result'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$GameRoomToJson(GameRoom instance) => <String, dynamic>{
      'objectId': instance.id,
      'room_code': instance.roomCode,
      'couple_id': instance.coupleId,
      'game_type': instance.gameType,
      'status': instance.status,
      'player1_id': instance.player1Id,
      'player2_id': instance.player2Id,
      'player1_ready': instance.player1Ready,
      'player2_ready': instance.player2Ready,
      'game_data': instance.gameData,
      'result': instance.result,
    };
