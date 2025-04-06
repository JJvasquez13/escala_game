import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/player.dart';

class GameScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final game = gameProvider.currentGame;
    final player = gameProvider.currentPlayer;

    if (game == null || player == null) {
      return Scaffold(
        body: Center(
            child: Text('Error: No se encontró el juego o el jugador')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Juego - Código: ${game.gameCode}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jugador: ${player.name}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Text('Materiales disponibles:', style: TextStyle(fontSize: 16)),
            Expanded(
              child: ListView.builder(
                itemCount: player.materials.length,
                itemBuilder: (context, index) {
                  final material = player.materials[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(material.type ?? 'Desconocido'),
                          // Manejo de null
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  gameProvider.placeMaterial(
                                    material.id ?? '', // Manejo de null
                                    'main',
                                    'left',
                                  );
                                },
                                child: Text('Balanza Principal - Izquierda'),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  gameProvider.placeMaterial(
                                    material.id ?? '', // Manejo de null
                                    'main',
                                    'right',
                                  );
                                },
                                child: Text('Balanza Principal - Derecha'),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  gameProvider.placeMaterial(
                                    material.id ?? '', // Manejo de null
                                    'secondary',
                                    'left',
                                  );
                                },
                                child: Text('Balanza Secundaria - Izquierda'),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  gameProvider.placeMaterial(
                                    material.id ?? '', // Manejo de null
                                    'secondary',
                                    'right',
                                  );
                                },
                                child: Text('Balanza Secundaria - Derecha'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text('Balanza Principal:', style: TextStyle(fontSize: 16)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Izquierda: ${game.mainBalanceState.leftSide
                    .length} materiales'),
                Text('Derecha: ${game.mainBalanceState.rightSide
                    .length} materiales'),
              ],
            ),
            SizedBox(height: 20),
            Text('Balanza Secundaria:', style: TextStyle(fontSize: 16)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Izquierda: ${game.secondaryBalanceState.leftSide
                    .length} materiales'),
                Text('Derecha: ${game.secondaryBalanceState.rightSide
                    .length} materiales'),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
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
              child: Text('Hacer Adivinanza'),
            ),
          ],
        ),
      ),
    );
  }
}