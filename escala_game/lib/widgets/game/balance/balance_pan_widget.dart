import 'package:flutter/material.dart';
import '../../../models/game.dart';
import 'material_item_widget.dart';
import '../../../utils/styles.dart';

class BalancePanWidget extends StatelessWidget {
  final bool isLeft;
  final List<MaterialItem> items;
  final bool isMain;
  final VoidCallback onTap;
  final Function(DragTargetDetails<String>) onAccept;

  const BalancePanWidget({
    Key? key,
    required this.isLeft,
    required this.items,
    required this.isMain,
    required this.onTap,
    required this.onAccept,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = isMain ? Colors.amber[600]! : Colors.grey[400]!;

    return DragTarget<String>(
      onAcceptWithDetails: onAccept,
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [defaultShadow()],
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
                      spacing: 2,
                      runSpacing: 2,
                      children: items.map((item) =>
                          MaterialItemWidget(item: item)).toList(),
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
}