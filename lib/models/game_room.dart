/// 游戏房间模型
class GameRoom {
  final String id;
  final String roomCode;
  final String coupleId;
  final String gameType;
  final String status;
  final String player1Id;
  final String? player2Id;
  final bool player1Ready;
  final bool player2Ready;
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

  factory GameRoom.fromMap(Map<String, dynamic> map) {
    return GameRoom(
      id: map['objectId'] as String,
      roomCode: map['room_code'] as String,
      coupleId: map['couple_id'] as String,
      gameType: map['game_type'] as String,
      status: map['status'] as String,
      player1Id: map['player1_id'] as String,
      player2Id: map['player2_id'] as String?,
      player1Ready: (map['player1_ready'] as bool?) ?? false,
      player2Ready: (map['player2_ready'] as bool?) ?? false,
      gameData: Map<String, dynamic>.from((map['game_data'] as Map?) ?? {}),
      result: map['result'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'room_code': roomCode,
      'couple_id': coupleId,
      'game_type': gameType,
      'status': status,
      'player1_id': player1Id,
      'player2_id': player2Id,
      'player1_ready': player1Ready,
      'player2_ready': player2Ready,
      'game_data': gameData,
      'result': result,
    };
  }

  bool get isReady => player1Ready && player2Ready;
  bool get isFull => player2Id != null;
}
