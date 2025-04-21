class Game {
  final String id;
  final String gameCode;
  final Map<String, int> materialWeights;
  final BalanceState mainBalanceState;
  final BalanceState secondaryBalanceState;
  final String state;
  final int currentPlayerIndex;
  final int currentTeam; // Nuevo: equipo actual
  final int roundTimeSeconds; // Nuevo: tiempo por turno
  final int timeRemaining; // Nuevo: tiempo restante en el turno actual
  final int materialsPlacedThisTurn; // Nuevo: materiales colocados en este turno
  final List<String> players;
  final String? creatorId;
  final DateTime startTime; // Nuevo: hora de inicio del juego
  final DateTime? endTime; // Nuevo: hora de fin del juego
  final List<String> winners; // Nuevo: lista de ganadores

  Game({
    required this.id,
    required this.gameCode,
    required this.materialWeights,
    required this.mainBalanceState,
    required this.secondaryBalanceState,
    required this.state,
    required this.currentPlayerIndex,
    required this.currentTeam,
    required this.roundTimeSeconds,
    required this.timeRemaining,
    required this.materialsPlacedThisTurn,
    required this.players,
    this.creatorId,
    required this.startTime,
    this.endTime,
    required this.winners,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    try {
      return Game(
        id: json['_id']?.toString() ?? '',
        gameCode: json['gameCode']?.toString() ?? '',
        materialWeights: Map<String, int>.from(json['materialWeights'] ?? {}),
        mainBalanceState: BalanceState.fromJson(json['mainBalanceState'] ??
            {'leftSide': [], 'rightSide': [], 'isBalanced': false}),
        secondaryBalanceState: BalanceState.fromJson(
            json['secondaryBalanceState'] ??
                {'leftSide': [], 'rightSide': [], 'isBalanced': false}),
        state: json['state']?.toString() ?? 'waiting',
        currentPlayerIndex: json['currentPlayerIndex'] is int
            ? json['currentPlayerIndex']
            : 0,
        currentTeam: json['currentTeam'] is int ? json['currentTeam'] : 1,
        roundTimeSeconds: json['roundTimeSeconds'] is int
            ? json['roundTimeSeconds']
            : 60,
        timeRemaining: json['timeRemaining'] is int ? json['timeRemaining'] : 0,
        materialsPlacedThisTurn: json['materialsPlacedThisTurn'] is int
            ? json['materialsPlacedThisTurn']
            : 0,
        players: (json['players'] as List<dynamic>? ?? []).map((p) =>
            p.toString()).toList(),
        creatorId: json['creatorId']?.toString(),
        startTime: json['startTime'] != null ? DateTime.tryParse(
            json['startTime'].toString()) ?? DateTime.now() : DateTime.now(),
        endTime: json['endTime'] != null ? DateTime.tryParse(
            json['endTime'].toString()) : null,
        winners: (json['winners'] as List<dynamic>? ?? []).map((w) =>
            w.toString()).toList(),
      );
    } catch (e) {
      print('Error al parsear Game desde JSON: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'gameCode': gameCode,
      'materialWeights': materialWeights,
      'mainBalanceState': {
        'leftSide': mainBalanceState.leftSide.map((item) =>
        {
          'type': item.type,
          'playerId': item.playerId,
        }).toList(),
        'rightSide': mainBalanceState.rightSide.map((item) =>
        {
          'type': item.type,
          'playerId': item.playerId,
        }).toList(),
        'isBalanced': mainBalanceState.isBalanced,
      },
      'secondaryBalanceState': {
        'leftSide': secondaryBalanceState.leftSide.map((item) =>
        {
          'type': item.type,
          'playerId': item.playerId,
        }).toList(),
        'rightSide': secondaryBalanceState.rightSide.map((item) =>
        {
          'type': item.type,
          'playerId': item.playerId,
        }).toList(),
        'isBalanced': secondaryBalanceState.isBalanced,
      },
      'state': state,
      'currentPlayerIndex': currentPlayerIndex,
      'currentTeam': currentTeam,
      'roundTimeSeconds': roundTimeSeconds,
      'timeRemaining': timeRemaining,
      'materialsPlacedThisTurn': materialsPlacedThisTurn,
      'players': players,
      'creatorId': creatorId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'winners': winners,
    };
  }
}

class BalanceState {
  final List<MaterialItem> leftSide;
  final List<MaterialItem> rightSide;
  final bool isBalanced;

  BalanceState({
    required this.leftSide,
    required this.rightSide,
    required this.isBalanced,
  });

  factory BalanceState.fromJson(Map<String, dynamic> json) {
    try {
      return BalanceState(
        leftSide: (json['leftSide'] as List<dynamic>? ?? [])
            .map((item) => MaterialItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        rightSide: (json['rightSide'] as List<dynamic>? ?? [])
            .map((item) => MaterialItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        isBalanced: json['isBalanced'] == true,
      );
    } catch (e) {
      print('Error al parsear BalanceState desde JSON: $e');
      rethrow;
    }
  }
}

class MaterialItem {
  final String type;
  final String playerId;

  MaterialItem({required this.type, required this.playerId});

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    try {
      return MaterialItem(
        type: json['type']?.toString() ?? '',
        playerId: json['playerId']?.toString() ?? '',
      );
    } catch (e) {
      print('Error al parsear MaterialItem desde JSON: $e');
      rethrow;
    }
  }
}