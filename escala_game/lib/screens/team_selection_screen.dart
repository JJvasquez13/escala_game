import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/player.dart';

class TeamSelectionScreen extends StatelessWidget {
  final String gameCode;

  const TeamSelectionScreen({Key? key, required this.gameCode})
      : super(key: key);

  bool _canStartGame(List<Player> players) {
    final teamCounts = <int, int>{};
    for (var player in players) {
      teamCounts[player.groupId] = (teamCounts[player.groupId] ?? 0) + 1;
    }
    return teamCounts.length >= 2; // Requiere al menos 2 equipos con jugadores
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Equipos')),
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
                'Jugadores y Equipos',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: gameProvider.players.length,
                itemBuilder: (context, index) {
                  final player = gameProvider.players[index];
                  return ListTile(
                    title: Text(
                      player.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Equipo ${player.groupId}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _canStartGame(gameProvider.players)
                    ? () async {
                  try {
                    await gameProvider.startGame();
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al iniciar el juego: $e')),
                    );
                  }
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent, // Botón destacado
                ),
                child: const Text(
                  'Iniciar Juego',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
            if (!_canStartGame(gameProvider.players))
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Se necesitan al menos 2 equipos con jugadores',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}