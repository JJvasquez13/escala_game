import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'team_selection_screen.dart';
import 'game_screen.dart';

class LobbyScreen extends StatelessWidget {
  final String gameCode;

  const LobbyScreen({Key? key, required this.gameCode}) : super(key: key);

  // Método para cambiar de equipo
  static Future<void> _changeTeam(BuildContext context, GameProvider gameProvider, int newTeam) async {
    if (gameProvider.currentPlayer == null) return;
    if (gameProvider.currentPlayer!.groupId == newTeam) return; // No hacer nada si ya está en ese equipo
    
    try {
      await gameProvider.changeTeam(newTeam);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cambiar de equipo: $e')),
      );
    }
  }

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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Jugadores Conectados',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      if (gameProvider.currentPlayer != null)
                        Column(
                          children: [
                            const Text(
                              'Cambia tu equipo:',
                              style: TextStyle(fontSize: 16, color: Colors.white70),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8.0,
                              alignment: WrapAlignment.center,
                              children: [
                                for (int i = 1; i <= 5; i++)
                                  InkWell(
                                    onTap: () async {
                                      // No permitir cambio si el juego ya comenzó
                                      if (gameProvider.currentGame?.state == 'waiting') {
                                        try {
                                          await _changeTeam(context, gameProvider, i);
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error al cambiar de equipo: $e')),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: gameProvider.currentPlayer?.groupId == i
                                            ? Colors.blue.shade700
                                            : Colors.blue.shade900,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: gameProvider.currentPlayer?.groupId == i
                                              ? Colors.white
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(
                                        'Equipo $i',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: gameProvider.currentPlayer?.groupId == i
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                    ],
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