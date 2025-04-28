import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'; // Añadido para BuildContext
import 'dart:async';
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
  bool _isPaused = false;
  Timer? _pauseTimer;
  int? _pauseStartTime;
  bool _gameEndedByBalance = false;
  int? _lastTurnTeam;

  // Tracking player votes and correct answers
  final Map<String, List<Map<String, dynamic>>> _playerVotes = {};
  final Map<String, int> _playerCorrectGuesses = {};
  bool _voteResultsDisplayed = false;

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
    webSocketService.connect((message) async {
      final type = message['type'];

      switch (type) {
        case 'CONNECTED':
          print('Connected to WebSocket');
          break;
        case 'PLAYER_JOINED':
          creatorId = message['creatorId'];
          creatorName = message['creatorName'];
          fetchPlayers();
          notifyListeners();
          break;
        case 'PLAYER_VOTED':
          // Actualizar las puntuaciones cuando otro jugador vota
          if (message['gameCode'] == currentGame?.gameCode && 
              message.containsKey('playerId') && 
              message.containsKey('correctGuesses')) {
            final playerId = message['playerId'];
            final correctGuesses = message['correctGuesses'];
            
            // Si no es el jugador actual (para evitar duplicación)
            if (playerId != currentPlayer?.id) {
              // Registrar que este jugador ha votado
              if (!_playerVotes.containsKey(playerId)) {
                _playerVotes[playerId] = [];
              }
              
              // Actualizar puntuación
              syncPlayerVotes(playerId, correctGuesses);
            }
          }
          break;
        case 'ALL_VOTES_COMPLETED':
          // Sincronizar todas las puntuaciones y mostrar resultados
          if (message['gameCode'] == currentGame?.gameCode && 
              message.containsKey('playerVotes')) {
            // Sincronizar puntuaciones y equipo ganador
            syncAllVotes(message['playerVotes']);
            
            // Actualizar info del ganador
            if (message.containsKey('winningTeam')) {
              final winningTeam = message['winningTeam'];
              // Actualizar juego con el ganador
              currentGame = Game.fromJson({
                ...currentGame!.toJson(),
                'winners': [winningTeam],
                'state': 'finished',
              });
            }
            
            // Marcar que se han mostrado los resultados
            _voteResultsDisplayed = true;
            
            // FORZAR cierre de diálogo de votación y mostrar resultados inmediatamente
            _showVotingResults();
            
            // Notificar a cualquier listener registrado
            _notifyVoteResultListeners(null);
          }
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
          currentGame =
              await apiService.getGame(message['gameCode']);
          creatorId = message['creatorId'] ?? creatorId;
          creatorName = message['creatorName'] ?? creatorName;
          localTimeRemaining = currentGame!.timeRemaining;
          notifyListeners();
          break;
        case 'PLAYER_LEFT':
          fetchPlayers();
          notifyListeners();
          break;
          
        case 'PLAYER_TEAM_CHANGED':
          // Actualizar inmediatamente cuando un jugador cambia de equipo
          if (message['gameCode'] == currentGame?.gameCode && 
              message.containsKey('playerId') && 
              message.containsKey('newTeam')) {
            
            final changedPlayerId = message['playerId'];
            final newTeam = message['newTeam'];
            
            // Actualizar el jugador actual si es él quien cambió de equipo
            if (currentPlayer != null && currentPlayer!.id == changedPlayerId) {
              currentPlayer = Player(
                id: currentPlayer!.id,
                name: currentPlayer!.name,
                gameId: currentPlayer!.gameId,
                groupId: newTeam,
                materials: currentPlayer!.materials,
                isEliminated: currentPlayer!.isEliminated,
                hasGuessed: currentPlayer!.hasGuessed,
                pieces: currentPlayer!.pieces,
                turnOrder: currentPlayer!.turnOrder,
                guesses: currentPlayer!.guesses,
                connectionData: currentPlayer!.connectionData,
                isReady: currentPlayer!.isReady,
              );
            }
            
            // Actualizar también en la lista de todos los jugadores
            for (int i = 0; i < players.length; i++) {
              if (players[i].id == changedPlayerId) {
                players[i] = Player(
                  id: players[i].id,
                  name: players[i].name,
                  gameId: players[i].gameId,
                  groupId: newTeam,
                  materials: players[i].materials,
                  isEliminated: players[i].isEliminated,
                  hasGuessed: players[i].hasGuessed,
                  pieces: players[i].pieces,
                  turnOrder: players[i].turnOrder,
                  guesses: players[i].guesses,
                  connectionData: players[i].connectionData,
                  isReady: players[i].isReady,
                );
                break;
              }
            }
            notifyListeners();
          }
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
            // Only update timer if not paused due to balanced state
            if (!_isPaused) {
              currentGame = Game.fromJson({
                ...currentGame!.toJson(),
                'timeRemaining': message['timeRemaining'],
              });
              lastServerTime = message['serverTime'];
              localTimeRemaining = currentGame!.timeRemaining;
              notifyListeners();
            }
          }
          break;
        case 'TURN_CHANGED':
          if (currentGame != null &&
              currentGame!.gameCode == message['gameCode']) {
            // Store the last team for validation later
            _lastTurnTeam = currentGame!.currentTeam;
            
            currentGame = Game.fromJson({
              ...currentGame!.toJson(),
              'currentTeam': message['currentTeam'],
              'timeRemaining': message['timeRemaining'],
            });
            lastServerTime = message['serverTime'];
            localTimeRemaining = currentGame!.timeRemaining;
            
            // Clear used materials when turn changes
            if (_lastTurnTeam != currentGame!.currentTeam) {
              _usedMaterials.clear();
            }
            
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

  Future<void> changeTeam(int newTeam) async {
    try {
      if (currentGame == null || currentPlayer == null) {
        throw Exception('No hay juego o jugador activo');
      }
      
      if (currentGame!.state != 'waiting') {
        throw Exception('No puedes cambiar de equipo una vez que la partida ha comenzado');
      }

      // Actualizar el jugador en el servidor
      currentPlayer = await apiService.updatePlayerTeam(
        currentGame!.gameCode,
        currentPlayer!.id,
        newTeam
      );
      
      // Notificar a todos los clientes conectados a través de WebSocket
      webSocketService.sendMessage({
        'type': 'PLAYER_TEAM_CHANGED',
        'gameCode': currentGame!.gameCode,
        'playerId': currentPlayer!.id,
        'newTeam': newTeam,
      });
      
      // Actualizar la lista de jugadores
      await fetchPlayers();
      notifyListeners();
    } catch (e) {
      print('Error al cambiar de equipo: $e');
      rethrow;
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
      // Check if game has ended due to balanced scale
      if (_gameEndedByBalance) {
        throw Exception('El juego ha terminado porque la balanza está balanceada. Solo se pueden hacer adivinanzas.');
      }
      
      // Check if material was from a previous turn and should not be allowed
      if (_lastTurnTeam != null && _lastTurnTeam != currentGame!.currentTeam && _usedMaterials.contains(materialId)) {
        throw Exception('No puedes usar materiales de turnos anteriores');
      }
      
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
    // If game is in balanced/voting state or we don't have time data, return the current timer value
    if (lastServerTime == null || localTimeRemaining == null || _isPaused || currentGame?.mainBalanceState.isBalanced == true) {
      return localTimeRemaining ?? currentGame?.timeRemaining ?? 0;
    }
    
    // Otherwise calculate the actual time remaining based on elapsed time
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final elapsedSinceLastUpdate = (currentTime - lastServerTime!) ~/ 1000;
    return (localTimeRemaining! - elapsedSinceLastUpdate).clamp(
        0, currentGame!.roundTimeSeconds);
  }

  bool get isPaused => _isPaused;
  bool get gameEndedByBalance => _gameEndedByBalance;

  void pauseTimer() {
    if (!_isPaused && currentGame != null && localTimeRemaining != null) {
      _isPaused = true;
      _pauseStartTime = DateTime.now().millisecondsSinceEpoch;
      _gameEndedByBalance = currentGame!.mainBalanceState.isBalanced;
      
      // Broadcast to all players that the timer is paused due to balanced state
      if (_gameEndedByBalance && currentPlayer != null) {
        webSocketService.sendMessage({
          'type': 'BALANCE_ACHIEVED',
          'gameCode': currentGame!.gameCode,
          'timeRemaining': localTimeRemaining,
          'playerId': currentPlayer!.id,
        });
      }
      
      notifyListeners();
    }
  }

  void resumeTimer() {
    if (_isPaused && _pauseStartTime != null) {
      _isPaused = false;

      // No adjustment needed as we're keeping localTimeRemaining frozen while paused
      lastServerTime = DateTime.now().millisecondsSinceEpoch;

      notifyListeners();
    }
  }

  // Methods for voting system
  // Resultados de votación acumulados
  final List<Function(BuildContext)> _voteResultListeners = [];
  
  // Añadir un listener para cuando todos los jugadores hayan votado
  void addVoteResultListener(Function(BuildContext) listener) {
    _voteResultListeners.add(listener);
  }
  
  // Limpiar listeners
  void clearVoteResultListeners() {
    _voteResultListeners.clear();
  }
  
  // Llamar a todos los listeners registrados
  void _notifyVoteResultListeners(BuildContext? context) {
    // Si no tenemos contexto, no podemos notificar a los listeners
    // ya que necesitan un contexto válido
    if (context != null) {
      for (var listener in _voteResultListeners) {
        listener(context);
      }
    }
    // Limpiar listeners en cualquier caso
    _voteResultListeners.clear();
  }

  // Sincronizar los votos de los jugadores recibidos via WebSocket
  void syncPlayerVotes(String playerId, int correctGuesses) {
    // Solo actualizar si el jugador existe y está en la lista
    if (players.any((p) => p.id == playerId)) {
      _playerCorrectGuesses[playerId] = correctGuesses;
      
      // Para jugadores que no han recibido sus votos, se guarda como array vacío
      if (!_playerVotes.containsKey(playerId)) {
        _playerVotes[playerId] = [];
      }
      
      // Verificar si todos los jugadores han votado después de esta actualización
      bool allPlayersVoted = true;
      for (var player in players) {
        if (!_playerVotes.containsKey(player.id)) {
          allPlayersVoted = false;
          break;
        }
      }
      
      // Si todos han votado, mostrar resultados automáticamente
      if (allPlayersVoted && !_voteResultsDisplayed) {
        _showVotingResults();
      }
      
      notifyListeners();
    }
  }
  
  // Método para mostrar automáticamente los resultados de votación
  void _showVotingResults() {
    // Marcar que se han mostrado los resultados
    _voteResultsDisplayed = true;
    
    // Calcular el equipo ganador
    final winningTeam = getWinningTeam();
    
    if (currentGame != null && winningTeam != null) {
      // Actualizar el juego local con el ganador
      currentGame = Game.fromJson({
        ...currentGame!.toJson(),
        'winners': [winningTeam],
        'state': 'finished',
      });
      
      // Actualizar en el servidor
      apiService.updateGame(currentGame!.gameCode, {
        'winners': [winningTeam],
        'state': 'finished'
      }).catchError((e) => print('Error al actualizar ganador: $e'));
      
      // Enviar evento para todos los jugadores
      webSocketService.sendMessage({
        'type': 'ALL_VOTES_COMPLETED',
        'gameCode': currentGame!.gameCode,
        'playerVotes': _playerVotes.map((id, votes) => MapEntry(id, {
          'votes': votes,
          'correctGuesses': _playerCorrectGuesses[id] ?? 0,
        })),
        'materialWeights': currentGame!.materialWeights,
        'winner': getWinner(),
        'winningTeam': winningTeam,
        'teamScores': getTeamScores(),
      });
    }
    
    notifyListeners();
  }
  
  // Método para cerrar diálogo de votación y mostrar resultados inmediatamente
  void _closeVotingDialogAndShowResults() {
    // Esta función será utilizada directamente por cualquier parte del código
    // que necesite mostrar los resultados de votación
    
    // Intentamos encontrar y usar el GuessButtonWidget para mostrar resultados
    // Las puntuaciones ya están sincronizadas gracias a syncPlayerVotes y syncAllVotes
    
    // Cuando esta función es llamada, el mecanismo de eventos de WebSocket ya
    // se encarga de notificar a todos los dispositivos conectados,
    // y la puntuación para todos los equipos ya está sincronizada
    
    // Si hay listeners en espera, debemos notificarlos primero
    if (!_voteResultListeners.isEmpty) {
      // No podemos pasar un contexto específico aquí
      _notifyVoteResultListeners(null);
    }
  }
  
  // Sincronizar todos los votos (para cuando se recibe ALL_VOTES_COMPLETED)
  void syncAllVotes(Map<String, dynamic> playerVotesData) {
    // Limpiar datos anteriores para evitar inconsistencias
    _playerCorrectGuesses.clear();
    _playerVotes.clear();
    
    // Procesar todos los votos recibidos
    playerVotesData.forEach((playerId, voteData) {
      if (voteData is Map) {
        // Procesamiento estándar para formato completo
        if (voteData['votes'] != null) {
          _playerVotes[playerId] = List<Map<String, dynamic>>.from(voteData['votes']);
        } else {
          _playerVotes[playerId] = [];
        }
        
        if (voteData['correctGuesses'] != null) {
          _playerCorrectGuesses[playerId] = voteData['correctGuesses'];
        } else {
          _playerCorrectGuesses[playerId] = 0;
        }
      } else {
        // Si recibimos solo el número de aciertos (formato simple)
        _playerVotes[playerId] = [];
        _playerCorrectGuesses[playerId] = voteData is int ? voteData : 0;
      }
    });
    
    // Asegurar que todos los jugadores actuales tengan una entrada en los mapas
    for (var player in players) {
      if (!_playerVotes.containsKey(player.id)) {
        _playerVotes[player.id] = [];
      }
      if (!_playerCorrectGuesses.containsKey(player.id)) {
        _playerCorrectGuesses[player.id] = 0;
      }
    }
    
    // Marcar que los resultados se han mostrado
    _voteResultsDisplayed = true;
    
    notifyListeners();
  }
  
  Future<void> submitVote(List<Map<String, dynamic>> votes, [BuildContext? context]) async {
    // Evitar votar más de una vez
    if (currentPlayer == null || currentGame == null || hasVoted(currentPlayer!.id)) {
      return;
    }
    
    // Guardar los votos del jugador actual
    _playerVotes[currentPlayer!.id] = votes;
    
    // Calcular aciertos
    int correctGuesses = 0;
    for (var vote in votes) {
      String materialType = vote['type'];
      int guessedWeight = vote['weight'];
      int actualWeight = currentGame?.materialWeights[materialType] ?? 0;
      
      if (guessedWeight == actualWeight) {
        correctGuesses++;
      }
    }
    
    // Guardar los aciertos del jugador actual localmente
    _playerCorrectGuesses[currentPlayer!.id] = correctGuesses;
    
    // Broadcast del voto a todos los jugadores para sincronizar
    webSocketService.sendMessage({
      'type': 'PLAYER_VOTED',
      'gameCode': currentGame!.gameCode,
      'playerId': currentPlayer!.id,
      'playerName': currentPlayer!.name,
      'teamId': currentPlayer!.groupId,
      'correctGuesses': correctGuesses,
    });
    
    // Si todos los materiales fueron adivinados correctamente
    if (correctGuesses == votes.length) {
      await makeGuess(votes);
    }
    
    // Verificar si todos los jugadores han votado
    bool allPlayersVoted = true;
    for (var player in players) {
      if (!_playerVotes.containsKey(player.id)) {
        allPlayersVoted = false;
        break;
      }
    }
    
    // Si todos han votado, mostrar automáticamente los resultados
    if (allPlayersVoted && !_voteResultsDisplayed) {
      // Usar el método centralizado para mostrar resultados
      _showVotingResults();
      
      // Adicionalmente notificar el listener con el contexto si existe
      if (context != null) {
        _notifyVoteResultListeners(context);
      }
      
      // Para el jugador que envió el último voto, mostrar resultados inmediatamente
      _closeVotingDialogAndShowResults();
    }
    
    notifyListeners();
  }

  // Devuelve las puntuaciones de cada jugador individualmente
  Map<String, int> getPlayerScores() {
    final Map<String, int> playerScores = {};

    players.forEach((player) {
      playerScores[player.id] = _playerCorrectGuesses[player.id] ?? 0;
    });

    return playerScores;
  }
  
  // Calcular la puntuación por equipos
  Map<int, int> getTeamScores() {
    final scores = <int, int>{};
    
    // Inicializar puntuaciones para todos los equipos a 0
    final allTeams = <int>{...players.map((p) => p.groupId)};
    for (var teamId in allTeams) {
      scores[teamId] = 0;
    }
    
    // Inicializar todos los equipos con al menos un jugador
    for (var player in players) {
      if (!scores.containsKey(player.groupId)) {
        scores[player.groupId] = 0;
      }
    }
    
    // Sumar las adivinanzas correctas por equipo
    _playerCorrectGuesses.forEach((playerId, correctGuesses) {
      final player = players.firstWhere(
        (p) => p.id == playerId,
        orElse: () => null as Player,
      );
      
      if (player != null) {
        final groupId = player.groupId;
        scores[groupId] = (scores[groupId] ?? 0) + correctGuesses;
      }
    });
    
    return scores;
  }

  // Retorna el equipo ganador (número de equipo)
  int? getWinningTeam() {
    final teamScores = getTeamScores();
    if (teamScores.isEmpty) return null;
    
    int? maxTeam;
    int maxScore = -1;
    
    // Para cada equipo, verificar si tiene la puntuación más alta
    teamScores.forEach((team, score) {
      if (score > maxScore) {
        maxScore = score;
        maxTeam = team;
      }
    });
    
    // Si todos tienen 0 puntos, declarar ganador al primer equipo con jugadores
    if (maxScore == 0) {
      // Verificar qué equipos tienen jugadores
      final teamsWithPlayers = <int>{};
      for (var player in players) {
        teamsWithPlayers.add(player.groupId);
      }
      
      // Si hay equipos con jugadores, elegir el primero como ganador
      if (teamsWithPlayers.isNotEmpty) {
        return teamsWithPlayers.first;
      }
    }
    
    return maxTeam;
  }
  
  // Retorna el nombre del equipo ganador (para mostrar en UI)
  String? getWinner() {
    final winningTeam = getWinningTeam();
    if (winningTeam == null) {
      return null;
    }
    
    return "Equipo $winningTeam";
  }

  // Verifica si un jugador ha votado
  bool hasVoted(String playerId) {
    return _playerVotes.containsKey(playerId);
  }
  
  // Verifica si todos los jugadores han votado
  bool get allPlayersVoted {
    if (players.isEmpty) return false;
    
    for (var player in players) {
      if (!_playerVotes.containsKey(player.id)) {
        return false;
      }
    }
    return true;
  }
  
  // Indica si se deben mostrar los resultados de la votación
  bool get shouldShowVotingResults {
    return _voteResultsDisplayed || allPlayersVoted;
  }
  
  // Obtiene los pesos de los materiales del juego actual
  Map<String, dynamic> getMaterialWeights() {
    return currentGame?.materialWeights ?? {};
  }
}