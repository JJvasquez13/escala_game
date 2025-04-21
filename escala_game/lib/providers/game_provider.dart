import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../services/storage_service.dart';
import '../models/game.dart';
import '../models/player.dart';

class GameProvider with ChangeNotifier {
  final ApiService apiService = ApiService();
  final WebSocketService webSocketService = WebSocketService();
  final StorageService storageService = StorageService();

  Game? currentGame;
  Player? currentPlayer;
  List<Player> players = [];
  String? playerName;
  String? creatorId;
  String? creatorName;
  String? _selectedMaterial;
  final List<String> _usedMaterials = [];
  Map<String, dynamic>? revealedMaterialWeight;
  int? lastServerTime;
  int? localTimeRemaining;

  GameProvider() {
    _loadPlayerName();
    connectWebSocket();
  }

  Future<void> _loadPlayerName() async {
    playerName = await storageService.getPlayerName();
    notifyListeners();
  }

  Future<void> savePlayerName(String name) async {
    playerName = name;
    await storageService.savePlayerName(name);
    notifyListeners();
  }

  void connectWebSocket() {
    webSocketService.connect((message) {
      switch (message['type']) {
        case 'PLAYER_JOINED':
          creatorId = message['creatorId'];
          creatorName = message['creatorName'];
          fetchPlayers();
          notifyListeners();
          break;
        case 'GAME_UPDATED':
          currentGame = Game.fromJson(message['gameState']);
          notifyListeners();
          break;
        case 'MATERIAL_PLACED':
          fetchGame();
          fetchPlayers();
          notifyListeners();
          break;
        case 'GUESS_MADE':
          fetchGame();
          fetchPlayers();
          if (message['guessResult'] == true) {
            storageService.saveGameToHistory(
              currentGame!.gameCode,
              'Ganaste',
              currentPlayer!.groupId,
            );
          }
          notifyListeners();
          break;
        case 'GAME_STARTED':
          currentGame = Game.fromJson(message['gameState']);
          creatorId = message['creatorId'] ?? creatorId;
          creatorName = message['creatorName'] ?? creatorName;
          localTimeRemaining = currentGame!.timeRemaining;
          notifyListeners();
          break;
        case 'PLAYER_LEFT':
          fetchPlayers();
          notifyListeners();
          break;
        case 'GAME_ENDED':
          currentGame = Game.fromJson(message['gameState']);
          storageService.saveGameToHistory(
            currentGame!.gameCode,
            'Terminado',
            currentPlayer!.groupId,
          );
          localTimeRemaining = 0;
          notifyListeners();
          break;
        case 'TIMER_UPDATE':
          if (currentGame != null &&
              currentGame!.gameCode == message['gameCode']) {
            currentGame = Game.fromJson({
              ...currentGame!.toJson(),
              'timeRemaining': message['timeRemaining'],
            });
            lastServerTime = message['serverTime'];
            localTimeRemaining = currentGame!.timeRemaining;
            notifyListeners();
          }
          break;
        case 'TURN_CHANGED':
          if (currentGame != null &&
              currentGame!.gameCode == message['gameCode']) {
            currentGame = Game.fromJson({
              ...currentGame!.toJson(),
              'currentTeam': message['currentTeam'],
              'timeRemaining': message['timeRemaining'],
            });
            lastServerTime = message['serverTime'];
            localTimeRemaining = currentGame!.timeRemaining;
            notifyListeners();
          }
          break;
        case 'PENALTY_APPLIED':
          fetchGame();
          fetchPlayers();
          notifyListeners();
          break;
        case 'MATERIAL_WEIGHT_REVEALED':
          if (currentGame != null &&
              currentGame!.gameCode == message['gameCode']) {
            revealedMaterialWeight = {
              'material': message['material'],
              'weight': message['weight'],
            };
            notifyListeners();
          }
          break;
        case 'PLAYER_ELIMINATED':
          if (currentGame != null &&
              currentGame!.gameCode == message['gameCode']) {
            final playerId = message['playerId'];
            final playerIndex = players.indexWhere((p) => p.id == playerId);
            if (playerIndex != -1) {
              // Actualizar el jugador en la lista players
              players[playerIndex] =
                  players[playerIndex].copyWith(isEliminated: true);
              // Si el jugador eliminado es el currentPlayer, actualizarlo también
              if (playerId == currentPlayer!.id) {
                currentPlayer = currentPlayer!.copyWith(isEliminated: true);
              }
              notifyListeners();
            }
          }
          break;
      }
    });
  }

  Future<void> createGame({int roundTimeSeconds = 60}) async {
    try {
      if (playerName == null) {
        throw Exception('Por favor, ingresa un nombre antes de crear un juego');
      }
      currentGame =
      await apiService.createGame(roundTimeSeconds: roundTimeSeconds);
      await joinGame(currentGame!.gameCode, playerName!, 1);
      creatorId = currentPlayer!.id;
      creatorName = currentPlayer!.name;
      _usedMaterials.clear();
      revealedMaterialWeight = null;
      localTimeRemaining = null;
      lastServerTime = null;
      notifyListeners();
    } catch (e) {
      print('Error al crear el juego: $e');
      rethrow;
    }
  }

  Future<void> joinGame(String gameCode, String playerName, int groupId) async {
    try {
      if (currentGame != null && currentGame!.gameCode != gameCode) {
        currentGame = null;
        currentPlayer = null;
        players.clear();
        _usedMaterials.clear();
        revealedMaterialWeight = null;
        localTimeRemaining = null;
        lastServerTime = null;
      }
      currentGame = await apiService.getGame(gameCode);
      currentPlayer =
      await apiService.createPlayer(gameCode, playerName, groupId);
      webSocketService.sendMessage({
        'type': 'JOIN_GAME',
        'gameCode': gameCode,
        'playerId': currentPlayer!.id,
      });
      await storageService.saveGameToHistory(gameCode, 'En curso', groupId);
      await fetchPlayers();
      _usedMaterials.clear();
      notifyListeners();
    } catch (e) {
      await storageService.saveGameToHistory(gameCode, 'Fallido', groupId);
      print('Error al unirse al juego: $e');
      rethrow;
    }
  }

  Future<void> fetchGame() async {
    try {
      if (currentGame != null) {
        currentGame = await apiService.getGame(currentGame!.gameCode);
        localTimeRemaining = currentGame!.timeRemaining;
        notifyListeners();
      }
    } catch (e) {
      print('Error al obtener el juego: $e');
    }
  }

  Future<void> fetchPlayers() async {
    try {
      if (currentGame != null) {
        players = await apiService.getPlayers(currentGame!.id);
        if (currentPlayer != null) {
          final updatedPlayer = players.firstWhere(
                (p) => p.id == currentPlayer!.id,
            orElse: () => currentPlayer!,
          );
          currentPlayer = updatedPlayer;
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching players: $e');
      players = [];
      notifyListeners();
    }
  }

  Future<void> placeMaterial(String materialId, String balanceType,
      String side) async {
    try {
      if (currentGame!.currentTeam != currentPlayer!.groupId) {
        throw Exception('No es el turno de tu equipo');
      }
      if (currentPlayer!.isEliminated) {
        throw Exception('Estás eliminado y no puedes realizar acciones');
      }
      if (currentPlayer!.materials.length <= 1) {
        throw Exception(
            'No tienes suficientes materiales para colocar (mínimo 2)');
      }
      final result = await apiService.placeMaterial(
          currentPlayer!.id, materialId, balanceType, side);
      _usedMaterials.add(materialId);
      currentGame = Game.fromJson({
        ...currentGame!.toJson(),
        'materialsPlacedThisTurn': result['materialsPlacedThisTurn'],
      });
      notifyListeners();
    } catch (e) {
      print('Error al colocar material: $e');
      rethrow;
    }
  }

  Future<void> makeGuess(List<Map<String, dynamic>> guesses) async {
    try {
      if (currentGame!.currentTeam != currentPlayer!.groupId) {
        throw Exception('No es el turno de tu equipo');
      }
      if (currentPlayer!.isEliminated) {
        throw Exception('Estás eliminado y no puedes realizar acciones');
      }
      if (currentPlayer!.materials.length <= 1) {
        throw Exception(
            'No tienes suficientes materiales para hacer una adivinanza (mínimo 2)');
      }
      final result = await apiService.makeGuess(currentPlayer!.id, guesses);
      currentPlayer = currentPlayer!.copyWith(
        pieces: result['newPiecesTotal'],
        hasGuessed: true,
      );
      currentGame = Game.fromJson(result['gameState']);
      notifyListeners();
    } catch (e) {
      print('Error al hacer la adivinanza: $e');
      rethrow;
    }
  }

  Future<void> startGame() async {
    try {
      await apiService.startGame(currentGame!.gameCode);
      webSocketService.sendMessage({
        'type': 'START_GAME',
        'gameCode': currentGame!.gameCode,
        'playerId': currentPlayer!.id,
      });
    } catch (e) {
      print('Error al iniciar el juego: $e');
      rethrow;
    }
  }

  bool isCreator() {
    return currentPlayer != null && creatorId != null &&
        currentPlayer!.id == creatorId;
  }

  String? get selectedMaterial => _selectedMaterial;

  void selectMaterial(String materialId) {
    _selectedMaterial = materialId;
    notifyListeners();
  }

  void clearSelectedMaterial() {
    _selectedMaterial = null;
    notifyListeners();
  }

  List<String> get usedMaterials => _usedMaterials;

  Future<void> leaveGame() async {
    try {
      if (currentGame != null && currentPlayer != null) {
        webSocketService.sendMessage({
          'type': 'LEAVE_GAME',
          'gameCode': currentGame!.gameCode,
          'playerId': currentPlayer!.id,
        });
        currentGame = null;
        currentPlayer = null;
        players.clear();
        _usedMaterials.clear();
        revealedMaterialWeight = null;
        localTimeRemaining = null;
        lastServerTime = null;
        notifyListeners();
      }
    } catch (e) {
      print('Error al salir del juego: $e');
      rethrow;
    }
  }

  int getAdjustedTimeRemaining() {
    if (lastServerTime == null || localTimeRemaining == null) {
      return currentGame?.timeRemaining ?? 0;
    }
    final currentTime = DateTime
        .now()
        .millisecondsSinceEpoch;
    final elapsedSinceLastUpdate = (currentTime - lastServerTime!) ~/ 1000;
    return (localTimeRemaining! - elapsedSinceLastUpdate).clamp(
        0, currentGame!.roundTimeSeconds);
  }
}