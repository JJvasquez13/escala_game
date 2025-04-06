import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/storage_service.dart';
import 'lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController gameCodeController = TextEditingController();
  final TextEditingController playerNameController = TextEditingController();
  final StorageService storageService = StorageService();
  List<String> gameHistory = [];
  bool showHistory = false;

  @override
  void initState() {
    super.initState();
    _loadGameHistory();
  }

  Future<void> _loadGameHistory() async {
    gameHistory = await storageService.getGameHistory();
    setState(() {});
  }

  Future<void> _showNameDialog(BuildContext context, GameProvider gameProvider,
      {required VoidCallback onSuccess}) async {
    if (gameProvider.playerName != null) {
      onSuccess();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ingresa tu nombre'),
          content: TextField(
            controller: playerNameController,
            decoration: const InputDecoration(hintText: 'Tu Nombre'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final name = playerNameController.text.trim();
                if (name.isNotEmpty) {
                  gameProvider.savePlayerName(name);
                  Navigator.pop(context);
                  onSuccess();
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade900, Colors.purple.shade800],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Escala Game',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black45,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  gameProvider.playerName != null
                      ? 'Bienvenido, ${gameProvider.playerName}!'
                      : '¡Juega y descubre los pesos!',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 48),
                _buildMenuButton(
                  context: context,
                  label: 'Crear Partida',
                  onPressed: () async {
                    await _showNameDialog(
                        context, gameProvider, onSuccess: () async {
                      try {
                        await gameProvider.createGame();
                        if (gameProvider.currentGame != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LobbyScreen(
                                    gameCode: gameProvider.currentGame!
                                        .gameCode,
                                  ),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error al crear el juego: $e')),
                        );
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  context: context,
                  label: 'Unirse a un Juego',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Unirse a un Juego'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: gameCodeController,
                                decoration: const InputDecoration(
                                    labelText: 'Código del Juego'),
                              ),
                              if (gameProvider.playerName == null)
                                TextField(
                                  controller: playerNameController,
                                  decoration: const InputDecoration(
                                      labelText: 'Tu Nombre (Opcional)'),
                                ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final gameCode = gameCodeController.text.trim();
                                final playerName = gameProvider.playerName ??
                                    (playerNameController.text
                                        .trim()
                                        .isNotEmpty
                                        ? playerNameController.text.trim()
                                        : 'Jugador Temporal');
                                if (gameCode.isNotEmpty) {
                                  if (gameProvider.playerName == null &&
                                      playerName != 'Jugador Temporal') {
                                    await gameProvider.savePlayerName(
                                        playerName);
                                  }
                                  try {
                                    await gameProvider.joinGame(
                                        gameCode, playerName);
                                    Navigator.pop(context);
                                    if (gameProvider.currentGame != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              LobbyScreen(
                                                gameCode: gameProvider
                                                    .currentGame!.gameCode,
                                              ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(
                                          'Error al unirse al juego: $e')),
                                    );
                                  }
                                }
                              },
                              child: const Text('Unirse'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const Spacer(),
                _buildHistorySection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade900,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
      ),
      child: Text(label),
    );
  }

  Widget _buildHistorySection() {
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
              Icon(
                showHistory ? Icons.expand_less : Icons.expand_more,
                color: Colors.white,
              ),
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
            child: gameHistory.isEmpty
                ? const Text(
              'No hay partidas jugadas',
              style: TextStyle(color: Colors.white70),
            )
                : Column(
              children: [
                ...gameHistory.map((entry) =>
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        entry,
                        style: const TextStyle(color: Colors.white),
                      ),
                    )),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    await storageService.clearGameHistory();
                    setState(() {
                      gameHistory = [];
                    });
                  },
                  child: const Text(
                    'Limpiar Historial',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}