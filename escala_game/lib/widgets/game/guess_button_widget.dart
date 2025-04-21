import 'package:flutter/material.dart';
import '../../models/game.dart';
import '../../models/player.dart';
import '../../providers/game_provider.dart';
import 'minimal_dialog.dart';

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

  void _makeGuess() {
    final guesses = [
      {'type': 'red', 'weight': 5},
      {'type': 'yellow', 'weight': 3},
      {'type': 'green', 'weight': 2},
      {'type': 'blue', 'weight': 4},
      {'type': 'purple', 'weight': 1},
    ];
    gameProvider.makeGuess(guesses);
  }

  bool _canPerformAction(BuildContext context) {
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
    final canGuess = game.currentTeam == player.groupId &&
        !player.isEliminated &&
        player.materials.length > 1;

    return Center(
      child: ElevatedButton(
        onPressed: canGuess
            ? _makeGuess
            : () {
          _canPerformAction(context);
          onRestrictedAction?.call();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: canGuess ? Colors.blueGrey[700] : Colors.grey,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Hacer Adivinanza',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}