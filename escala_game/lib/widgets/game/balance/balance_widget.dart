import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/game_provider.dart';
import '../../../models/game.dart';
import '../../../models/player.dart';
import 'balance_pan_widget.dart';
import 'triangle_painter.dart';
import '../../../utils/styles.dart';

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
        duration: const Duration(milliseconds: 500), vsync: this);
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
    double leftWeight = widget.leftItems.fold(
        0.0, (sum, item) => sum + (widget.weights[item.type] ?? 0));
    double rightWeight = widget.rightItems.fold(
        0.0, (sum, item) => sum + (widget.weights[item.type] ?? 0));

    double weightDifference = (leftWeight - rightWeight).abs();
    double maxTilt = 0.3;
    double maxOffset = 30.0;

    double targetTilt = 0.0;
    double targetLeftOffset = 0.0;
    double targetRightOffset = 0.0;

    if (leftWeight != rightWeight) {
      double tiltFactor = (leftWeight - rightWeight) /
          (leftWeight + rightWeight).clamp(1, double.infinity);
      targetTilt = maxTilt * tiltFactor;

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
          child: Text('Balanza secundaria visible solo para tu equipo',
              style: TextStyle(color: Colors.grey)),
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
          Positioned(
            bottom: 0,
            child: Container(
              width: 120,
              height: 30,
              decoration: BoxDecoration(
                color: widget.isMain ? Colors.amber[800]! : Colors.grey[600]!,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [defaultShadow()],
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            child: CustomPaint(
              painter: TrianglePainter(
                  color: widget.isMain ? Colors.amber[700]! : Colors
                      .grey[500]!),
              child: const SizedBox(width: 40, height: 60),
            ),
          ),
          AnimatedBuilder(
            animation: _tiltAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _tiltAnimation.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 50,
                      child: Container(
                        width: 200,
                        height: 20,
                        decoration: BoxDecoration(
                          color: widget.isMain ? Colors.amber[600]! : Colors
                              .grey[400]!,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [defaultShadow()],
                        ),
                      ),
                    ),
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
                            style: TextStyle(color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 70,
                      left: 10,
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
                            BalancePanWidget(
                              isLeft: true,
                              items: widget.leftItems,
                              isMain: widget.isMain,
                              onTap: () {
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
                              onAccept: (details) {
                                widget.onPlace?.call(details.data,
                                    widget.isMain ? 'main' : 'secondary',
                                    'left');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 70,
                      right: 10,
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
                            BalancePanWidget(
                              isLeft: false,
                              items: widget.rightItems,
                              isMain: widget.isMain,
                              onTap: () {
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
                              onAccept: (details) {
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