import 'package:flutter/material.dart';
import '../../providers/game_provider.dart';
import '../../models/game.dart';

class TimerWidget extends StatelessWidget {
  final GameProvider gameProvider;

  const TimerWidget({Key? key, required this.gameProvider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final game = gameProvider.currentGame;
    if (game == null) return const SizedBox.shrink();

    final timeRemaining = gameProvider.getAdjustedTimeRemaining();
    final progressValue = timeRemaining / game.roundTimeSeconds;
    final isPaused = gameProvider.isPaused;

    // Determinar si estamos en fase de votación (balanza balanceada)
    final isBalanced = game.mainBalanceState.isBalanced;
    final gamePhase = isBalanced ? 'Fase de Adivinanza' : 'Turno del Equipo ${game.currentTeam}';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.blueGrey[800]!.withOpacity(0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isBalanced ? Icons.emoji_events : Icons.groups,
                    color: isBalanced ? Colors.amber : Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    gamePhase,
                    style: TextStyle(
                      fontSize: 16,
                      color: isBalanced ? Colors.amber : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (isPaused || isBalanced)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(
                        Icons.pause_circle_filled,
                        color: Colors.amber,
                        size: 18,
                      ),
                    ),
                  Text(
                    isBalanced
                      ? 'Fase de votación'
                      : (isPaused ? 'Tiempo pausado: $timeRemaining s' : 'Tiempo: $timeRemaining s'),
                    style: TextStyle(
                      fontSize: 16,
                      color: isPaused || isBalanced ? Colors.amber : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!isBalanced) 
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: progressValue.clamp(0.0, 1.0),
                  backgroundColor: Colors.white30,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPaused ? Colors.amber : 
                    (timeRemaining <= 10 ? Colors.red : Colors.blueGrey[300]!),
                  ),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                if (timeRemaining <= 10 && !isPaused)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.timer, color: Colors.red[300], size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '¡Poco tiempo!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[300],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.withOpacity(0.4)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 14),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Todos los equipos deben adivinar los pesos de los materiales',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}