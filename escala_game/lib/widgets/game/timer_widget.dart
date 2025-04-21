import 'package:flutter/material.dart';
import '../../providers/game_provider.dart';

class TimerWidget extends StatelessWidget {
  final GameProvider gameProvider;

  const TimerWidget({Key? key, required this.gameProvider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final game = gameProvider.currentGame;
    if (game == null) return const SizedBox.shrink();

    final timeRemaining = gameProvider.getAdjustedTimeRemaining();
    final progressValue = timeRemaining / game.roundTimeSeconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Turno del Equipo ${game.currentTeam}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Tiempo: $timeRemaining s',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progressValue.clamp(0.0, 1.0),
          backgroundColor: Colors.white30,
          valueColor: AlwaysStoppedAnimation<Color>(
            timeRemaining <= 10 ? Colors.red : Colors.blueGrey[300]!,
          ),
          minHeight: 8,
        ),
      ],
    );
  }
}