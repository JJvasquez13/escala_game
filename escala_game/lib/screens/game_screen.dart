import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/game.dart';
import '../models/player.dart';
import '../widgets/balance_widget.dart';
import '../widgets/material_list_widget.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final game = gameProvider.currentGame;
        final player = gameProvider.currentPlayer;
        final players = gameProvider.players;

        if (game == null || player == null) {
          return const Scaffold(
            body: Center(
                child: Text('Error: No se encontró el juego o el jugador')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Juego - Código: ${game.gameCode}'),
            backgroundColor: Colors.blueGrey[900],
            elevation: 0,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueGrey[800]!, Colors.blueGrey[600]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jugador: ${player.name} (Equipo ${player.groupId})',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Balanza Principal (Visible para todos):',
                    style: TextStyle(fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  BalanceWidget(
                    isMain: true,
                    leftItems: game.mainBalanceState.leftSide,
                    rightItems: game.mainBalanceState.rightSide,
                    weights: game.materialWeights,
                    isBalanced: game.mainBalanceState.isBalanced,
                    onPlace: gameProvider.placeMaterial,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Balanza Secundaria (Visible para tu equipo):',
                    style: TextStyle(fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  BalanceWidget(
                    isMain: false,
                    leftItems: game.secondaryBalanceState.leftSide,
                    rightItems: game.secondaryBalanceState.rightSide,
                    weights: game.materialWeights,
                    isBalanced: game.secondaryBalanceState.isBalanced,
                    showForTeam: player.groupId,
                    players: players,
                    onPlace: gameProvider.placeMaterial,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Materiales disponibles:',
                    style: TextStyle(fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  MaterialListWidget(
                    materials: player.materials,
                    onPlace: gameProvider.placeMaterial,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        final guesses = [
                          {'type': 'red', 'weight': 5},
                          {'type': 'yellow', 'weight': 3},
                          {'type': 'green', 'weight': 2},
                          {'type': 'blue', 'weight': 4},
                          {'type': 'purple', 'weight': 1},
                        ];
                        gameProvider.makeGuess(guesses);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[700],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius
                            .circular(12)),
                      ),
                      child: const Text(
                        'Hacer Adivinanza',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}