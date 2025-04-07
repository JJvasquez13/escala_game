import 'package:flutter/material.dart';
import '../../utils/styles.dart';

class MenuButtonWidget extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const MenuButtonWidget(
      {Key? key, required this.label, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: menuButtonStyle,
      child: Text(label),
    );
  }
}