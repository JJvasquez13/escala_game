import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'game_screen.dart';

class LobbyScreen extends StatelessWidget {
  final String gameCode; // Add gameCode parameter

  const LobbyScreen({Key? key, required this.gameCode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        if (gameProvider.currentGame == null) {
          return const Scaffold(
            body: Center(child: Text('Error: No se encontró el juego')),
          );
        }

        if (gameProvider.currentGame!.state == 'playing') {
          return GameScreen(); // Remove 'const' since GameScreen isn't const yet
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Lobby - ${gameProvider.currentGame?.gameCode}'),
          ),
          body: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                    'Jugadores Conectados', style: TextStyle(fontSize: 20)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: gameProvider.players.length,
                  itemBuilder: (context, index) {
                    final player = gameProvider.players[index];
                    return ListTile(
                      title: Text(player.name),
                      trailing: player.id == gameProvider.creatorId
                          ? const Text('Creador', style: TextStyle(
                          color: Colors.blue))
                          : null,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: gameProvider.isCreator()
                    ? ElevatedButton(
                  onPressed: gameProvider.players.length >= 2
                      ? () async {
                    try {
                      await gameProvider.startGame();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Error al iniciar el juego: $e')),
                      );
                    }
                  }
                      : null,
                  child: const Text('Iniciar Juego'),
                )
                    : Text(
                  gameProvider.creatorName != null
                      ? 'Esperando a que ${gameProvider
                      .creatorName} inicie la partida...'
                      : 'Esperando a que el creador inicie la partida...',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}