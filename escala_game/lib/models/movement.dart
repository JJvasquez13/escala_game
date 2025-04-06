class Movement {
  final String id;
  final String gameId;
  final String playerId;
  final String actionType;
  final Map<String, dynamic> data;

  Movement({
    required this.id,
    required this.gameId,
    required this.playerId,
    required this.actionType,
    required this.data,
  });

  factory Movement.fromJson(Map<String, dynamic> json) {
    return Movement(
      id: json['_id'],
      gameId: json['gameId'],
      playerId: json['playerId'],
      actionType: json['actionType'],
      data: json['data'] ?? {},
    );
  }
}