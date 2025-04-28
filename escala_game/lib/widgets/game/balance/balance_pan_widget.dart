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
    final mainColor = isMain ? const Color(0xFFBFA36F) : const Color(0xFF8E8E8E);
    final highlightColor = isMain ? const Color(0xFFD9C27E) : const Color(0xFFAAAAAA);
    final shadowColor = isMain ? const Color(0xFF9E8555) : const Color(0xFF666666);

    return DragTarget<String>(
      onAcceptWithDetails: onAccept,
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  highlightColor,
                  mainColor,
                  shadowColor,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: candidateData.isNotEmpty ? Colors.yellow.shade300 : Colors.transparent,
                width: candidateData.isNotEmpty ? 3 : 0,
              ),
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