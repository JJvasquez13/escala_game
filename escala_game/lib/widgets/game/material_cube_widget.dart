import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../models/player.dart';

class MaterialCubeWidget extends StatefulWidget {
  final PlayerMaterial material;
  final int index;
  final Function(String materialId, String balanceType, String side) onPlace;

  const MaterialCubeWidget({
    Key? key,
    required this.material,
    required this.index,
    required this.onPlace,
  }) : super(key: key);

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
                    color: Colors.black45, blurRadius: 5, offset: Offset(2, 2)),
              ],
            ),
            child: Center(
              child: Text(
                widget.material.type[0].toUpperCase(),
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            ),
          ),
        ),
        childWhenDragging: Container(
            width: 50, height: 50, color: Colors.grey[300]),
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
                  border: _isSelected ? Border.all(
                      color: Colors.white, width: 2) : null,
                  boxShadow: [
                    BoxShadow(color: Colors.black45,
                        blurRadius: 5,
                        offset: Offset(2, 2)),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.material.type[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
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
                      style: TextStyle(color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
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