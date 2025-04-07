import 'package:flutter/foundation.dart'; // Para ChangeNotifier
import '../services/api_service.dart'; // Para ApiService
import '../services/websocket_service.dart'; // Para WebSocketService
import '../services/storage_service.dart'; // Para StorageService
import '../models/game.dart'; // Para Game
import '../models/player.dart'; // Para Player

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
  final List<String> _usedMaterials = [
  ]; // Añadido para rastrear materiales usados

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
        case 'GUESS_MADE':
          fetchGame();
          fetchPlayers();
          if (message['type'] == 'GUESS_MADE' &&
              message['guessResult'] == true) {
            storageService.saveGameToHistory(
              currentGame!.gameCode,
              'Ganaste',
            );
          }
          notifyListeners();
          break;
        case 'GAME_STARTED':
          currentGame = Game.fromJson(message['gameState']);
          creatorId = message['creatorId'] ?? creatorId;
          creatorName = message['creatorName'] ?? creatorName;
          notifyListeners();
          break;
      }
    });
  }

  Future<void> createGame() async {
    try {
      if (playerName == null) {
        throw Exception('Por favor, ingresa un nombre antes de crear un juego');
      }
      currentGame = await apiService.createGame();
      await joinGame(currentGame!.gameCode, playerName!,
          1); // Asignamos equipo 1 al creador
      creatorId = currentPlayer!.id;
      creatorName = currentPlayer!.name;
      _usedMaterials.clear();
      notifyListeners();
    } catch (e) {
      print('Error al crear el juego: $e');
      rethrow;
    }
  }

  Future<void> joinGame(String gameCode, String playerName, int groupId) async {
    try {
      currentGame = await apiService.getGame(gameCode);
      currentPlayer =
      await apiService.createPlayer(gameCode, playerName, groupId);
      webSocketService.sendMessage({
        'type': 'JOIN_GAME',
        'gameCode': gameCode,
        'playerId': currentPlayer!.id,
      });
      await fetchPlayers();
      _usedMaterials.clear();
      notifyListeners();
    } catch (e) {
      print('Error al unirse al juego: $e');
      rethrow;
    }
  }

  Future<void> fetchGame() async {
    try {
      if (currentGame != null) {
        currentGame = await apiService.getGame(currentGame!.gameCode);
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
      await apiService.placeMaterial(
          currentPlayer!.id, materialId, balanceType, side);
      _usedMaterials.add(materialId); // Añadir el material a la lista de usados
      notifyListeners();
    } catch (e) {
      print('Error al colocar material: $e');
      rethrow;
    }
  }

  Future<void> makeGuess(List<Map<String, dynamic>> guesses) async {
    try {
      await apiService.makeGuess(currentPlayer!.id, guesses);
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

  // Métodos para manejar la selección de materiales
  String? get selectedMaterial => _selectedMaterial;

  void selectMaterial(String materialId) {
    _selectedMaterial = materialId;
    notifyListeners();
  }

  void clearSelectedMaterial() {
    _selectedMaterial = null;
    notifyListeners();
  }

  // Getter para los materiales usados
  List<String> get usedMaterials => _usedMaterials;
}