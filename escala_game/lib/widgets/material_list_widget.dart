import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/player.dart';
import 'material_cube_widget.dart';

class MaterialListWidget extends StatelessWidget {
  final List<PlayerMaterial> materials;
  final Function(String materialId, String balanceType, String side) onPlace;

  const MaterialListWidget(
      {Key? key, required this.materials, required this.onPlace})
      : super(key: key);

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