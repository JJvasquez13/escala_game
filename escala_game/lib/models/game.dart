class Game {
  final String id;
  final String gameCode;
  final Map<String, int> materialWeights;
  final BalanceState mainBalanceState;
  final BalanceState secondaryBalanceState;
  final String state;
  final int currentPlayerIndex;
  final List<String> players;
  final String? creatorId;

  Game({
    required this.id,
    required this.gameCode,
    required this.materialWeights,
    required this.mainBalanceState,
    required this.secondaryBalanceState,
    required this.state,
    required this.currentPlayerIndex,
    required this.players,
    this.creatorId,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['_id'],
      gameCode: json['gameCode'],
      materialWeights: Map<String, int>.from(json['materialWeights'] ?? {}),
      mainBalanceState: BalanceState.fromJson(json['mainBalanceState'] ??
          {'leftSide': [], 'rightSide': [], 'isBalanced': false}),
      secondaryBalanceState: BalanceState.fromJson(
          json['secondaryBalanceState'] ??
              {'leftSide': [], 'rightSide': [], 'isBalanced': false}),
      state: json['state'] ?? json['status'] ?? 'waiting',
      currentPlayerIndex: json['currentPlayerIndex'] ?? 0,
      players: List<String>.from(json['players'] ?? []),
      creatorId: json['creatorId'],
    );
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
          'playerId': item.playerId
        }).toList(),
        'rightSide': mainBalanceState.rightSide.map((item) =>
        {
          'type': item.type,
          'playerId': item.playerId
        }).toList(),
        'isBalanced': mainBalanceState.isBalanced,
      },
      'secondaryBalanceState': {
        'leftSide': secondaryBalanceState.leftSide.map((item) =>
        {
          'type': item.type,
          'playerId': item.playerId
        }).toList(),
        'rightSide': secondaryBalanceState.rightSide.map((item) =>
        {
          'type': item.type,
          'playerId': item.playerId
        }).toList(),
        'isBalanced': secondaryBalanceState.isBalanced,
      },
      'state': state,
      'currentPlayerIndex': currentPlayerIndex,
      'players': players,
      'creatorId': creatorId,
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
    return BalanceState(
      leftSide: (json['leftSide'] as List? ?? [])
          .map((item) => MaterialItem.fromJson(item))
          .toList(),
      rightSide: (json['rightSide'] as List? ?? [])
          .map((item) => MaterialItem.fromJson(item))
          .toList(),
      isBalanced: json['isBalanced'] ?? false,
    );
  }
}

class MaterialItem {
  final String type;
  final String playerId;

  MaterialItem({required this.type, required this.playerId});

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      type: json['type'] ?? '',
      playerId: json['playerId']?.toString() ?? '',
    );
  }
}