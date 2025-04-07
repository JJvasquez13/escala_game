import 'package:flutter/material.dart';
import '../models/game.dart';
import '../utils/styles.dart';

class MaterialItemWidget extends StatelessWidget {
  final MaterialItem item;

  const MaterialItemWidget({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final materialColor = materialColors[item.type.toLowerCase()] ??
        Colors.grey;

    return Transform(
      transform: Matrix4.identity()
        ..rotateX(0.3)
        ..rotateY(0.3),
      alignment: Alignment.center,
      child: Container(
        width: 20,
        height: 20,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: materialColor,
          boxShadow: [defaultShadow(blurRadius: 3, offset: const Offset(1, 1))],
        ),
        child: Center(
          child: Text(
            item.type[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}