import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/game.dart';
import '../models/player.dart';

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
                    'Jugador: ${player.name}',
                    style: const TextStyle(fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
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
                    onPlace: (materialId, balanceType, side) {
                      gameProvider.placeMaterial(materialId, balanceType, side);
                    },
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
                    onPlace: (materialId, balanceType, side) {
                      gameProvider.placeMaterial(materialId, balanceType, side);
                    },
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
                    onPlace: (materialId, balanceType, side) {
                      gameProvider.placeMaterial(materialId, balanceType, side);
                    },
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

// Widget para mostrar la lista de materiales como cubos arrastrables
class MaterialListWidget extends StatelessWidget {
  final List<PlayerMaterial> materials;
  final Function(String materialId, String balanceType, String side) onPlace;

  MaterialListWidget({required this.materials, required this.onPlace});

  @override
  Widget build(BuildContext context) {
    final usedMaterials = Provider
        .of<GameProvider>(context)
        .usedMaterials;
    final availableMaterials = materials.where((material) =>
    !usedMaterials.contains(material.id)).toList();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: availableMaterials
          .asMap()
          .entries
          .map((entry) {
        final index = entry.key;
        final material = entry.value;
        return MaterialCubeWidget(
          material: material,
          index: index,
          onPlace: onPlace,
        );
      }).toList(),
    );
  }
}

// Widget para mostrar un material como un cubo 3D arrastrable
class MaterialCubeWidget extends StatefulWidget {
  final PlayerMaterial material;
  final int index;
  final Function(String materialId, String balanceType, String side) onPlace;

  MaterialCubeWidget(
      {required this.material, required this.index, required this.onPlace});

  @override
  _MaterialCubeWidgetState createState() => _MaterialCubeWidgetState();
}

class _MaterialCubeWidgetState extends State<MaterialCubeWidget> {
  bool _isSelected = false;

  static const Map<String, Color> materialColors = {
    'red': Colors.red,
    'yellow': Colors.yellow,
    'green': Colors.green,
    'blue': Colors.blue,
    'purple': Colors.purple,
  };

  @override
  Widget build(BuildContext context) {
    final materialColor = materialColors[widget.material.type.toLowerCase()] ??
        Colors.grey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isSelected = !_isSelected;
        });
        if (_isSelected) {
          Provider.of<GameProvider>(context, listen: false).selectMaterial(
              widget.material.id);
        } else {
          Provider
              .of<GameProvider>(context, listen: false)
              .clearSelectedMaterial();
        }
      },
      child: Draggable<String>(
        data: widget.material.id,
        feedback: Transform(
          transform: Matrix4.identity()
            ..rotateX(0.3)
            ..rotateY(0.3),
          alignment: Alignment.center,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: materialColor,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 5,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.material.type[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ),
        childWhenDragging: Container(
          width: 50,
          height: 50,
          color: Colors.grey[300],
        ),
        child: Stack(
          children: [
            Transform(
              transform: Matrix4.identity()
                ..rotateX(0.3)
                ..rotateY(0.3),
              alignment: Alignment.center,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: materialColor,
                  border: _isSelected
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 5,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.material.type[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ),
            if (_isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Text(
                      'Toca la balanza',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Widget para mostrar la balanza
class BalanceWidget extends StatefulWidget {
  final bool isMain;
  final List<MaterialItem> leftItems;
  final List<MaterialItem> rightItems;
  final Map<String, int> weights;
  final bool isBalanced;
  final int? showForTeam;
  final List<Player>? players;
  final Function(String materialId, String balanceType, String side)? onPlace;

  const BalanceWidget({
    Key? key,
    required this.isMain,
    required this.leftItems,
    required this.rightItems,
    required this.weights,
    required this.isBalanced,
    this.showForTeam,
    this.players,
    this.onPlace,
  }) : super(key: key);

  @override
  _BalanceWidgetState createState() => _BalanceWidgetState();
}

class _BalanceWidgetState extends State<BalanceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _tiltAnimation;
  double _tilt = 0.0;
  double _leftPanOffset = 0.0;
  double _rightPanOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _tiltAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _updateTiltAndOffsets();
  }

  @override
  void didUpdateWidget(BalanceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.leftItems != widget.leftItems ||
        oldWidget.rightItems != widget.rightItems) {
      _updateTiltAndOffsets();
    }
  }

  void _updateTiltAndOffsets() {
    double leftWeight = widget.leftItems.fold(0.0, (sum, item) {
      return sum + (widget.weights[item.type] ?? 0);
    });
    double rightWeight = widget.rightItems.fold(0.0, (sum, item) {
      return sum + (widget.weights[item.type] ?? 0);
    });

    double weightDifference = (leftWeight - rightWeight).abs();
    double maxTilt = 0.3; // Máxima inclinación permitida
    double maxOffset = 30.0; // Máximo desplazamiento vertical de los platos

    double targetTilt = 0.0;
    double targetLeftOffset = 0.0;
    double targetRightOffset = 0.0;

    if (leftWeight != rightWeight) {
      // Calcular inclinación proporcional a la diferencia de peso
      double tiltFactor = (leftWeight - rightWeight) /
          (leftWeight + rightWeight).clamp(1, double.infinity);
      targetTilt = maxTilt * tiltFactor;

      // Calcular desplazamiento vertical proporcional
      double offsetFactor = weightDifference /
          (leftWeight + rightWeight).clamp(1, double.infinity);
      double offset = maxOffset * offsetFactor;
      if (leftWeight > rightWeight) {
        targetLeftOffset = offset;
        targetRightOffset = -offset;
      } else {
        targetLeftOffset = -offset;
        targetRightOffset = offset;
      }
    }

    _tiltAnimation = Tween<double>(begin: _tilt, end: targetTilt).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _tilt = targetTilt;
    _leftPanOffset = targetLeftOffset;
    _rightPanOffset = targetRightOffset;
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildMaterialItem(MaterialItem item) {
    const Map<String, Color> materialColors = {
      'red': Colors.red,
      'yellow': Colors.yellow,
      'green': Colors.green,
      'blue': Colors.blue,
      'purple': Colors.purple,
    };
    final materialColor = materialColors[item.type.toLowerCase()] ??
        Colors.grey;

    return Transform(
      transform: Matrix4.identity()
        ..rotateX(0.3)
        ..rotateY(0.3),
      alignment: Alignment.center,
      child: Container(
        width: 20,
        // Reducido para que quepan más materiales
        height: 20,
        margin: const EdgeInsets.all(1),
        // Reducido para menos espacio entre materiales
        decoration: BoxDecoration(
          color: materialColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 3,
              offset: Offset(1, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            item.type[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10, // Reducido para ajustar al tamaño
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalancePan(bool isLeft, VoidCallback onTap,
      Function(DragTargetDetails<String>) onAccept) {
    final items = isLeft ? widget.leftItems : widget.rightItems;
    final color = widget.isMain ? Colors.amber[600]! : Colors.grey[400]!;

    return DragTarget<String>(
      onAcceptWithDetails: onAccept,
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 100, // Aumentado de 80 a 100
            height: 100, // Aumentado de 80 a 100
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 5,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 2, // Espacio entre materiales
                      runSpacing: 2,
                      children: items.map<Widget>(_buildMaterialItem).toList(),
                    ),
                  ],
                ),
                if (candidateData.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayer = Provider
        .of<GameProvider>(context, listen: false)
        .currentPlayer;
    bool shouldShowSecondary = true;
    if (!widget.isMain && widget.showForTeam != null &&
        widget.players != null && currentPlayer != null) {
      shouldShowSecondary = currentPlayer.groupId == widget.showForTeam;
    }

    if (!widget.isMain && !shouldShowSecondary) {
      return const SizedBox(
        height: 250,
        child: Center(
          child: Text(
            'Balanza secundaria visible solo para tu equipo',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final selectedMaterial = context
        .watch<GameProvider>()
        .selectedMaterial;

    return Container(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base de la balanza
          Positioned(
            bottom: 0,
            child: Container(
              width: 120,
              height: 30,
              decoration: BoxDecoration(
                color: widget.isMain ? Colors.amber[800]! : Colors.grey[600]!,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Soporte triangular
          Positioned(
            bottom: 30,
            child: CustomPaint(
              painter: TrianglePainter(
                color: widget.isMain ? Colors.amber[700]! : Colors.grey[500]!,
              ),
              child: SizedBox(
                width: 40,
                height: 60,
              ),
            ),
          ),
          // Estructura de la balanza (viga, cadenas y platos)
          AnimatedBuilder(
            animation: _tiltAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _tiltAnimation.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Viga de la balanza
                    Positioned(
                      top: 50,
                      child: Container(
                        width: 200,
                        height: 20,
                        decoration: BoxDecoration(
                          color: widget.isMain ? Colors.amber[600]! : Colors
                              .grey[400]!,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Mensaje "¡Balanceado!" debajo de la viga
                    if (widget.isMain && widget.isBalanced)
                      Positioned(
                        top: 75,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '¡Balanceado!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    // Cadena y plato izquierdo
                    Positioned(
                      top: 70,
                      left: 10, // Ajustado para el plato más grande
                      child: Transform.translate(
                        offset: Offset(0, _leftPanOffset),
                        child: Column(
                          children: [
                            Container(
                              width: 2,
                              height: 10,
                              color: widget.isMain ? Colors.amber[700]! : Colors
                                  .grey[500]!,
                            ),
                            _buildBalancePan(
                              true,
                                  () {
                                if (selectedMaterial != null) {
                                  widget.onPlace?.call(selectedMaterial,
                                      widget.isMain ? 'main' : 'secondary',
                                      'left');
                                  Provider
                                      .of<GameProvider>(
                                      context, listen: false)
                                      .clearSelectedMaterial();
                                }
                              },
                                  (details) {
                                widget.onPlace?.call(details.data,
                                    widget.isMain ? 'main' : 'secondary',
                                    'left');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Cadena y plato derecho
                    Positioned(
                      top: 70,
                      right: 10, // Ajustado para el plato más grande
                      child: Transform.translate(
                        offset: Offset(0, _rightPanOffset),
                        child: Column(
                          children: [
                            Container(
                              width: 2,
                              height: 10,
                              color: widget.isMain ? Colors.amber[700]! : Colors
                                  .grey[500]!,
                            ),
                            _buildBalancePan(
                              false,
                                  () {
                                if (selectedMaterial != null) {
                                  widget.onPlace?.call(selectedMaterial,
                                      widget.isMain ? 'main' : 'secondary',
                                      'right');
                                  Provider
                                      .of<GameProvider>(
                                      context, listen: false)
                                      .clearSelectedMaterial();
                                }
                              },
                                  (details) {
                                widget.onPlace?.call(details.data,
                                    widget.isMain ? 'main' : 'secondary',
                                    'right');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Pintor personalizado para el soporte triangular
class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    final shadowPaint = Paint()
      ..color = Colors.black45
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(path, shadowPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}