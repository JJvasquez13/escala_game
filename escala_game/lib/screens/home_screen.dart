import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/storage_service.dart';
import 'lobby_screen.dart';
import '../widgets/home/menu_button_widget.dart';
import '../widgets/home/history_section_widget.dart';
import '../utils/styles.dart';

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
  int? selectedTeam;
  int? selectedTime; // Nuevo: para almacenar el tiempo seleccionado

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
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Por favor, ingresa un nombre válido')),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showTimeSelectionDialog(BuildContext context,
      GameProvider gameProvider) async {
    selectedTime = null; // Reiniciar el tiempo seleccionado

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Selecciona el tiempo por turno'),
              content: DropdownButton<int>(
                hint: const Text('Tiempo por turno (segundos)'),
                value: selectedTime,
                items: const [
                  DropdownMenuItem(value: 60, child: Text('60 segundos')),
                  DropdownMenuItem(value: 120, child: Text('120 segundos')),
                  DropdownMenuItem(value: 180, child: Text('180 segundos')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedTime = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedTime != null) {
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Por favor, selecciona un tiempo')),
                      );
                    }
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
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
                Text('Escala Game', style: titleStyle),
                const SizedBox(height: 16),
                Text(
                  gameProvider.playerName != null
                      ? 'Bienvenido, ${gameProvider.playerName}!'
                      : '¡Juega y descubre los pesos!',
                  style: subtitleStyle,
                ),
                const SizedBox(height: 48),
                MenuButtonWidget(
                  label: 'Crear Partida',
                  onPressed: () async {
                    await _showNameDialog(
                      context,
                      gameProvider,
                      onSuccess: () async {
                        await _showTimeSelectionDialog(context, gameProvider);
                        if (selectedTime != null) {
                          try {
                            await gameProvider.createGame(
                                roundTimeSeconds: selectedTime!);
                            if (gameProvider.currentGame != null) {
                              await _loadGameHistory();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      LobbyScreen(
                                          gameCode: gameProvider.currentGame!
                                              .gameCode),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error al crear el juego: $e')),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                MenuButtonWidget(
                  label: 'Unirse a un Juego',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (context, setState) {
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
                                  DropdownButton<int>(
                                    hint: const Text('Selecciona un equipo'),
                                    value: selectedTeam,
                                    items: [1, 2, 3, 4, 5].map((team) {
                                      return DropdownMenuItem<int>(
                                          value: team,
                                          child: Text('Equipo $team'));
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedTeam = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final gameCode = gameCodeController.text
                                        .trim();
                                    final playerName = gameProvider
                                        .playerName ??
                                        (playerNameController.text
                                            .trim()
                                            .isNotEmpty
                                            ? playerNameController.text.trim()
                                            : 'Jugador Temporal');
                                    if (gameCode.isNotEmpty &&
                                        selectedTeam != null) {
                                      if (gameProvider.playerName == null &&
                                          playerName != 'Jugador Temporal') {
                                        await gameProvider.savePlayerName(
                                            playerName);
                                      }
                                      try {
                                        await gameProvider.joinGame(
                                            gameCode, playerName,
                                            selectedTeam!);
                                        Navigator.pop(context);
                                        await _loadGameHistory();
                                        if (gameProvider.currentGame != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  LobbyScreen(
                                                      gameCode: gameProvider
                                                          .currentGame!
                                                          .gameCode),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger
                                            .of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Error al unirse al juego: $e')),
                                        );
                                        await _loadGameHistory();
                                      }
                                    } else {
                                      ScaffoldMessenger
                                          .of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Por favor, ingresa el código y selecciona un equipo')),
                                      );
                                    }
                                  },
                                  child: const Text('Unirse'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                const Spacer(),
                HistorySectionWidget(
                  gameHistory: gameHistory,
                  onClearHistory: () async {
                    await storageService.clearGameHistory();
                    setState(() {
                      gameHistory = [];
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}