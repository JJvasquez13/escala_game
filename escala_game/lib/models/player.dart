class Player {
  final String id;
  final String gameId;
  final String name;
  final int groupId;
  final int turnOrder;
  final int pieces;
  final List<PlayerMaterial> materials;
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
    try {
      return Player(
        id: json['_id']?.toString() ?? '',
        gameId: json['gameId']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Jugador Desconocido',
        groupId: json['groupId'] is int ? json['groupId'] : 0,
        turnOrder: json['turnOrder'] is int ? json['turnOrder'] : 0,
        pieces: json['pieces'] is int ? json['pieces'] : 2,
        materials: (json['materials'] as List<dynamic>? ?? [])
            .map((item) =>
            PlayerMaterial.fromJson(item as Map<String, dynamic>))
            .toList(),
        hasGuessed: json['hasGuessed'] == true,
        isEliminated: json['isEliminated'] == true,
        guesses: (json['guesses'] as List<dynamic>? ?? [])
            .map((item) => Guess.fromJson(item as Map<String, dynamic>))
            .toList(),
        connectionData: ConnectionData.fromJson(
            json['connectionData'] as Map<String, dynamic>? ?? {}),
        isReady: json['isReady'] == true,
      );
    } catch (e) {
      print('Error al parsear Player desde JSON: $e');
      rethrow;
    }
  }

  // Nuevo: método copyWith para crear una copia con valores modificados
  Player copyWith({
    String? id,
    String? gameId,
    String? name,
    int? groupId,
    int? turnOrder,
    int? pieces,
    List<PlayerMaterial>? materials,
    bool? hasGuessed,
    bool? isEliminated,
    List<Guess>? guesses,
    ConnectionData? connectionData,
    bool? isReady,
  }) {
    return Player(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      name: name ?? this.name,
      groupId: groupId ?? this.groupId,
      turnOrder: turnOrder ?? this.turnOrder,
      pieces: pieces ?? this.pieces,
      materials: materials ?? this.materials,
      hasGuessed: hasGuessed ?? this.hasGuessed,
      isEliminated: isEliminated ?? this.isEliminated,
      guesses: guesses ?? this.guesses,
      connectionData: connectionData ?? this.connectionData,
      isReady: isReady ?? this.isReady,
    );
  }
}

class PlayerMaterial {
  final String type;
  final String id;

  PlayerMaterial({
    required this.type,
    required this.id,
  });

  factory PlayerMaterial.fromJson(Map<String, dynamic> json) {
    try {
      return PlayerMaterial(
        type: json['type']?.toString() ?? 'unknown',
        id: json['id']?.toString() ?? '',
      );
    } catch (e) {
      print('Error al parsear PlayerMaterial desde JSON: $e');
      rethrow;
    }
  }
}

class Guess {
  final String type;
  final int? weight;
  final bool? isCorrect;
  final DateTime? time;

  Guess({
    required this.type,
    this.weight,
    this.isCorrect,
    this.time,
  });

  factory Guess.fromJson(Map<String, dynamic> json) {
    try {
      return Guess(
        type: json['type']?.toString() ?? 'unknown',
        weight: json['weight'] is int ? json['weight'] : null,
        isCorrect: json['isCorrect'] is bool ? json['isCorrect'] : null,
        time: json['time'] != null
            ? DateTime.tryParse(json['time'].toString())
            : null,
      );
    } catch (e) {
      print('Error al parsear Guess desde JSON: $e');
      rethrow;
    }
  }
}

class ConnectionData {
  final String ip;
  final String userAgent;
  final DateTime? lastConnection;

  ConnectionData({
    required this.ip,
    required this.userAgent,
    this.lastConnection,
  });

  factory ConnectionData.fromJson(Map<String, dynamic> json) {
    try {
      return ConnectionData(
        ip: json['ip']?.toString() ?? '',
        userAgent: json['userAgent']?.toString() ?? '',
        lastConnection: json['lastConnection'] != null
            ? DateTime.tryParse(json['lastConnection'].toString())
            : null,
      );
    } catch (e) {
      print('Error al parsear ConnectionData desde JSON: $e');
      rethrow;
    }
  }
}