import 'package:flutter/material.dart';
import '../../providers/game_provider.dart';

class RevealedMaterialWidget extends StatelessWidget {
  final GameProvider gameProvider;

  const RevealedMaterialWidget({Key? key, required this.gameProvider})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final revealedMaterialWeight = gameProvider.revealedMaterialWeight;

    if (revealedMaterialWeight == null) {
      return const SizedBox
          .shrink(); // No mostrar nada si no hay material revelado
    }

    final material = revealedMaterialWeight['material'] as String;
    final weight = revealedMaterialWeight['weight'] as int;

    return Card(
      color: Colors.blueGrey[700],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Material Revelado: $material pesa $weight',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}