class Player {
  final String id;
  final String gameId;
  final String name;
  final int groupId;
  final int turnOrder;
  final int pieces;
  final List<MaterialItem> materials;
  final bool hasGuessed;
  final bool isEliminated;
  final List<Guess> guesses;
  final ConnectionData connectionData;
  final bool isReady;

  Player({
    required this.id,
    required this.gameId,
    required this.name,
    required this.groupId,
    required this.turnOrder,
    required this.pieces,
    required this.materials,
    required this.hasGuessed,
    required this.isEliminated,
    required this.guesses,
    required this.connectionData,
    required this.isReady,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['_id']?.toString() ?? '',
      gameId: json['gameId']?.toString() ?? '',
      name: json['name'] ?? 'Jugador Desconocido',
      groupId: json['groupId'] ?? 0,
      turnOrder: json['turnOrder'] ?? 0,
      pieces: json['pieces'] ?? 2,
      materials: (json['materials'] as List? ?? [])
          .map((item) => MaterialItem.fromJson(item))
          .toList(),
      hasGuessed: json['hasGuessed'] ?? false,
      isEliminated: json['isEliminated'] ?? false,
      guesses: (json['guesses'] as List? ?? [])
          .map((item) => Guess.fromJson(item))
          .toList(),
      connectionData: ConnectionData.fromJson(json['connectionData'] ?? {}),
      isReady: json['isReady'] ?? false,
    );
  }
}

class MaterialItem {
  final String? type;
  final String? id;

  MaterialItem({this.type, this.id});

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      type: json['type']?.toString(),
      id: json['id']?.toString(),
    );
  }
}

class Guess {
  final String? type;
  final int? weight;
  final bool? isCorrect;
  final DateTime? time;

  Guess({this.type, this.weight, this.isCorrect, this.time});

  factory Guess.fromJson(Map<String, dynamic> json) {
    return Guess(
      type: json['type']?.toString(),
      weight: json['weight'] as int?,
      isCorrect: json['isCorrect'] as bool?,
      time: json['time'] != null ? DateTime.parse(json['time']) : null,
    );
  }
}

class ConnectionData {
  final String? ip;
  final String? userAgent;
  final DateTime? lastConnection;

  ConnectionData({this.ip, this.userAgent, this.lastConnection});

  factory ConnectionData.fromJson(Map<String, dynamic> json) {
    return ConnectionData(
      ip: json['ip']?.toString(),
      userAgent: json['userAgent']?.toString(),
      lastConnection: json['lastConnection'] != null
          ? DateTime.parse(json['lastConnection'])
          : null,
    );
  }
}