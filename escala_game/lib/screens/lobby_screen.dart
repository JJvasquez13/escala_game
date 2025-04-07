import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'team_selection_screen.dart';
import 'game_screen.dart';

class LobbyScreen extends StatelessWidget {
  final String gameCode;

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
          return const GameScreen();
        }

        return Scaffold(
          appBar: AppBar(title: Text('Lobby - ${gameProvider.currentGame
              ?.gameCode}')),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A237E), // Azul oscuro
                  Color(0xFF4A148C), // Morado oscuro
                ],
              ),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Jugadores Conectados',
                    style: TextStyle(fontSize: 20,
                        color: Colors.white), // Texto blanco para contraste
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: gameProvider.players.length,
                    itemBuilder: (context, index) {
                      final player = gameProvider.players[index];
                      return ListTile(
                        title: Text(
                          '${player.name} (Equipo ${player.groupId})',
                          style: const TextStyle(
                              color: Colors.white), // Contraste
                        ),
                        trailing: player.id == gameProvider.creatorId
                            ? const Text(
                          'Creador',
                          style: TextStyle(color: Colors.cyanAccent),
                        )
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
                        ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TeamSelectionScreen(gameCode: gameCode),
                        ),
                      );
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent, // Botón destacado
                    ),
                    child: const Text(
                      'Preparar Equipos e Iniciar',
                      style: TextStyle(color: Colors.black),
                    ),
                  )
                      : Text(
                    gameProvider.creatorName != null
                        ? 'Esperando a que ${gameProvider
                        .creatorName} inicie la partida...'
                        : 'Esperando a que el creador inicie la partida...',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}