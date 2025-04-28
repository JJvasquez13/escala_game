import 'package:flutter/material.dart';
import '../../models/game.dart';
import '../../models/player.dart';
import '../../providers/game_provider.dart';
import 'minimal_dialog.dart';
import 'voting_dialog_widget.dart';

class GuessButtonWidget extends StatelessWidget {
  final Game game;
  final Player player;
  final GameProvider gameProvider;
  final VoidCallback? onRestrictedAction;

  const GuessButtonWidget({
    Key? key,
    required this.game,
    required this.player,
    required this.gameProvider,
    this.onRestrictedAction,
  }) : super(key: key);

  void _makeGuess(BuildContext context) {
    if (game.mainBalanceState.isBalanced) {
      // If the main balance is balanced, show voting dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => VotingDialogWidget(
          gameProvider: gameProvider,
          onSubmitVote: (votes) {
            // Si el array de votos está vacío, significa que ya se procesó automáticamente
            // porque todos los jugadores han votado
            if (votes.isEmpty) {
              // Mostrar resultados directamente
              _showVoteResults(context);
            } else {
              // Este caso ocurre cuando el jugador presiona el botón de votar
              // No es necesario hacer nada más aquí, ya que la votación se maneja en VotingDialogWidget
              _showVoteResults(context);
            }
          },
        ),
      );
    } else {
      // Fallback to default behavior if balance is not balanced
      final guesses = [
        {'type': 'red', 'weight': 10},
        {'type': 'yellow', 'weight': 6},
        {'type': 'green', 'weight': 4},
        {'type': 'blue', 'weight': 8},
        {'type': 'purple', 'weight': 2},
      ];
      gameProvider.makeGuess(guesses);
    }
  }

  void _showVoteResults(BuildContext context) {
    // Obtener los pesos de los materiales
    final materialWeights = gameProvider.getMaterialWeights();
    
    // Obtener puntuaciones por equipo
    final teamScores = gameProvider.getTeamScores();
    
    // Obtener puntuaciones individuales
    final playerScores = gameProvider.getPlayerScores();
    
    // Obtener el equipo ganador 
    final winner = gameProvider.getWinner();
    final winningTeam = gameProvider.getWinningTeam();
    
    // Create widgets for material weights
    final materialWeightWidgets = <Widget>[];
    materialWeights.forEach((material, weight) {
      Color materialColor = Colors.grey;
      switch (material) {
        case 'red':
          materialColor = Colors.red;
          break;
        case 'yellow':
          materialColor = Colors.yellow;
          break;
        case 'green':
          materialColor = Colors.green;
          break;
        case 'blue':
          materialColor = Colors.blue;
          break;
        case 'purple':
          materialColor = Colors.purple;
          break;
      }
      
      String materialName = '';
      switch (material) {
        case 'red':
          materialName = 'Rojo';
          break;
        case 'yellow':
          materialName = 'Amarillo';
          break;
        case 'green':
          materialName = 'Verde';
          break;
        case 'blue':
          materialName = 'Azul';
          break;
        case 'purple':
          materialName = 'Púrpura';
          break;
        default:
          materialName = material;
      }
      
      materialWeightWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                color: materialColor,
                margin: const EdgeInsets.only(right: 8),
              ),
              Text(
                '$materialName: ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('$weight unidades'),
            ],
          ),
        ),
      );
    });

    // Crear widgets para las puntuaciones por equipo
    final teamScoreWidgets = <Widget>[];
    
    // Ordenar los equipos por puntuación (mayor a menor)
    final sortedTeams = teamScores.keys.toList()
      ..sort((a, b) => (teamScores[b] ?? 0).compareTo(teamScores[a] ?? 0));
    
    // Crear un widget para cada equipo con su puntuación
    for (var teamId in sortedTeams) {
      // Sólo mostrar equipos que tienen al menos un jugador
      if (gameProvider.players.any((p) => p.groupId == teamId)) {
        final score = teamScores[teamId] ?? 0;
        final isWinner = teamId == winningTeam;
        
        teamScoreWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Equipo $teamId:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isWinner ? Colors.green[700] : Colors.blueGrey[700],
                    fontSize: isWinner ? 18.0 : 16.0,
                  ),
                ),
                Text(
                  '$score aciertos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isWinner ? Colors.green[700] : Colors.black,
                    fontSize: isWinner ? 18.0 : 16.0,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    
    // Crear widgets para las puntuaciones individuales
    final playerScoreWidgets = <Widget>[];
    
    // Ordenar jugadores por puntuación
    final sortedPlayerIds = playerScores.keys.toList()
      ..sort((a, b) => (playerScores[b] ?? 0).compareTo(playerScores[a] ?? 0));
    
    for (var playerId in sortedPlayerIds) {
      final score = playerScores[playerId] ?? 0;
      final player = gameProvider.players.firstWhere(
        (p) => p.id == playerId,
        orElse: () => Player(
          id: playerId, 
          name: 'Unknown', 
          groupId: 0,
          gameId: '',
          materials: [],
          isEliminated: false,
          hasGuessed: false,
          pieces: 0,
          turnOrder: 0,
          guesses: [],
          connectionData: ConnectionData(ip: '', userAgent: ''),
          isReady: false
        ),
      );
      
      playerScoreWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${player.name} (Equipo ${player.groupId}):',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[700],
                ),
              ),
              Text(
                '$score aciertos',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // No permitir que el usuario cierre este diálogo, solo permitir volver al home
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Impedir que se cierre con el botón atrás
        child: AlertDialog(
          title: const Text('Resultados de adivinanzas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pesos de los materiales:', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...materialWeightWidgets,
                const Divider(height: 24),
                const Text('Puntuaciones por equipo:', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...teamScoreWidgets,
                const Divider(height: 24),
                const Text('Puntuaciones individuales:', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...playerScoreWidgets,
                const SizedBox(height: 16),
                if (winner != null) ...[              
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Ganador: $winner',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.home),
              label: const Text('Volver al inicio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // Salir del juego y volver al home
                gameProvider.leaveGame();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _canPerformAction(BuildContext context) {
    // Si la balanza está balanceada, cualquier jugador puede votar o ver resultados
    if (game.mainBalanceState.isBalanced) {
      if (player.isEliminated) {
        MinimalDialog.show(
          context,
          title: 'No puedes jugar',
          message: 'Estás eliminado y no puedes realizar acciones.',
        );
        return false;
      }
      // En fase de votación, todos pueden participar
      return true;
    }
    
    // Si no está balanceada, solo el equipo actual puede actuar
    if (game.currentTeam != player.groupId) {
      MinimalDialog.show(
        context,
        title: 'No es tu turno',
        message: 'Es el turno del Equipo ${game.currentTeam}.',
      );
      return false;
    }
    if (player.isEliminated) {
      MinimalDialog.show(
        context,
        title: 'No puedes jugar',
        message: 'Estás eliminado y no puedes realizar acciones.',
      );
      return false;
    }
    if (player.materials.length <= 1) {
      MinimalDialog.show(
        context,
        title: 'Materiales insuficientes',
        message: 'No tienes suficientes materiales para realizar esta acción (mínimo 2).',
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Si la balanza está balanceada, cualquier jugador puede votar o ver resultados
    final bool isBalanceBalanced = game.mainBalanceState.isBalanced;
    final bool canVoteInBalanced = !player.isEliminated && isBalanceBalanced;
    
    // Para fase normal de juego, solo el equipo actual puede actuar
    final bool canGuessNormal = game.currentTeam == player.groupId &&
        !player.isEliminated &&
        player.materials.length > 1;
    
    // Si el jugador ya ha votado, mostrar botón para ver resultados
    final bool hasVoted = gameProvider.hasVoted(player.id);
    
    // Si todos los jugadores han votado, mostrar automáticamente los resultados
    final bool shouldShowResults = gameProvider.shouldShowVotingResults;
    
    // Mostrar automáticamente los resultados si todos han votado
    if (shouldShowResults && isBalanceBalanced && game.endTime == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showVoteResults(context);
      });
    }
    
    return Center(
      child: Column(
        children: [
          if (isBalanceBalanced) 
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '¡La balanza está balanceada!',
                      style: TextStyle(
                        color: Colors.black87, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 16
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Todos los equipos deben adivinar los pesos',
                      style: TextStyle(
                        color: Colors.black87, 
                        fontSize: 14
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (hasVoted)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Ya has votado. ${gameProvider.allPlayersVoted ? "¡Todos han votado!" : "Esperando a los demás jugadores..."}',
                          style: TextStyle(
                            color: Colors.green[700], 
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ElevatedButton.icon(
            onPressed: isBalanceBalanced
                ? (hasVoted
                    ? () => _showVoteResults(context)
                    : (canVoteInBalanced ? () => _makeGuess(context) : null))
                : (canGuessNormal
                    ? () => _makeGuess(context)
                    : () {
                        _canPerformAction(context);
                        onRestrictedAction?.call();
                      }),
            icon: Icon(
              isBalanceBalanced
                  ? (hasVoted ? Icons.poll : Icons.lightbulb)
                  : Icons.psychology,
              color: Colors.white,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isBalanceBalanced
                  ? (hasVoted ? Colors.green[700] : Colors.amber[700])
                  : (canGuessNormal ? Colors.blueGrey[700] : Colors.grey[600]),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            label: Text(
              isBalanceBalanced
                  ? (hasVoted ? 'Ver Resultados' : 'Adivinar Pesos')
                  : 'Hacer Adivinanza',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}