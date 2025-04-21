import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/game.dart';
import '../models/player.dart';
import '../widgets/game/balance/balance_widget.dart';
import '../widgets/game/material_list_widget.dart';
import '../widgets/game/timer_widget.dart';
import '../widgets/game/minimal_dialog.dart';
import '../widgets/game/guess_button_widget.dart';
import '../widgets/game/revealed_material_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Timer? _timer;
  bool _hasShownTenSecondsWarning = false;
  int? _lastTurnTeam;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      final timeRemaining = gameProvider.getAdjustedTimeRemaining();
      if (timeRemaining <= 10 && timeRemaining > 0 &&
          !_hasShownTenSecondsWarning) {
        MinimalDialog.show(
          context,
          title: '¡Atención!',
          message: 'Quedan $timeRemaining segundos para el turno.',
        );
        _hasShownTenSecondsWarning = true;
      } else if (timeRemaining > 10) {
        _hasShownTenSecondsWarning = false;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _canPerformAction(Game game, Player player) {
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

        if (_lastTurnTeam != game.currentTeam) {
          _lastTurnTeam = game.currentTeam;
          _hasShownTenSecondsWarning = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            MinimalDialog.show(
              context,
              title: 'Cambio de turno',
              message: 'Es el turno del Equipo ${game.currentTeam}.',
            );
          });
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
                  const SizedBox(height: 10),
                  TimerWidget(gameProvider: gameProvider),
                  const SizedBox(height: 10),
                  RevealedMaterialWidget(gameProvider: gameProvider),
                  const SizedBox(height: 20),
                  const Text(
                    'Balanza Principal (Visible para todos):',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  BalanceWidget(
                    isMain: true,
                    leftItems: game.mainBalanceState.leftSide,
                    rightItems: game.mainBalanceState.rightSide,
                    weights: game.materialWeights,
                    isBalanced: game.mainBalanceState.isBalanced,
                    onPlace: (materialId, balanceType, side) {
                      if (_canPerformAction(game, player)) {
                        gameProvider.placeMaterial(
                            materialId, balanceType, side);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Balanza Secundaria (Visible para tu equipo):',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  BalanceWidget(
                    isMain: false,
                    leftItems: game.secondaryBalanceState.leftSide,
                    rightItems: game.secondaryBalanceState.rightSide,
                    weights: game.materialWeights,
                    isBalanced: game.secondaryBalanceState.isBalanced,
                    showForTeam: player.groupId,
                    players: players,
                    onPlace: (materialId, balanceType, side) {
                      if (_canPerformAction(game, player)) {
                        gameProvider.placeMaterial(
                            materialId, balanceType, side);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Materiales disponibles:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  MaterialListWidget(
                    materials: player.materials,
                    onPlace: (materialId, balanceType, side) {
                      if (_canPerformAction(game, player)) {
                        gameProvider.placeMaterial(
                            materialId, balanceType, side);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  GuessButtonWidget(
                    game: game,
                    player: player,
                    gameProvider: gameProvider,
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