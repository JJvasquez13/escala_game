import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../providers/game_provider.dart';
import '../../screens/lobby_screen.dart';

class HistorySectionWidget extends StatefulWidget {
  final List<String> gameHistory;
  final VoidCallback onClearHistory;

  const HistorySectionWidget(
      {Key? key, required this.gameHistory, required this.onClearHistory})
      : super(key: key);

  @override
  _HistorySectionWidgetState createState() => _HistorySectionWidgetState();
}

class _HistorySectionWidgetState extends State<HistorySectionWidget> {
  bool showHistory = false;

  void _retryJoin(BuildContext context, String gameCode, int team) async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final storageService = StorageService();
    final playerName = gameProvider.playerName ?? 'Jugador Temporal';

    try {
      await gameProvider.joinGame(gameCode, playerName, team);
      await storageService.saveGameToHistory(gameCode, 'En curso', team);
      if (gameProvider.currentGame != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LobbyScreen(gameCode: gameCode)),
        );
      }
    } catch (e) {
      await storageService.saveGameToHistory(gameCode, 'Fallido', team);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al intentar unirse de nuevo: $e')),
      );
    }
    setState(() {
      widget.gameHistory.clear();
      storageService.getGameHistory().then((history) {
        widget.gameHistory.addAll(history);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              showHistory = !showHistory;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Historial de Partidas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(showHistory ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white),
            ],
          ),
        ),
        if (showHistory)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: widget.gameHistory.isEmpty
                ? const Text('No hay partidas jugadas',
                style: TextStyle(color: Colors.white70))
                : Column(
              children: [
                ...widget.gameHistory.map((entry) {
                  final parts = entry.split(' - ');
                  final gameCode = parts[0];
                  final result = parts[1];
                  final team = int.parse(parts[2]);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$gameCode - $result - Equipo $team',
                          style: const TextStyle(color: Colors.white),
                        ),
                        if (result == 'Fallido')
                          TextButton(
                            onPressed: () =>
                                _retryJoin(context, gameCode, team),
                            child: const Text(
                              'Reintentar',
                              style: TextStyle(color: Colors.blueAccent),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: widget.onClearHistory,
                  child: const Text('Limpiar Historial',
                      style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}