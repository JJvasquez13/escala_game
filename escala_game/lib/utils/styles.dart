import 'package:flutter/material.dart';

const Map<String, Color> materialColors = {
  'red': Colors.red,
  'yellow': Colors.yellow,
  'green': Colors.green,
  'blue': Colors.blue,
  'purple': Colors.purple,
};

BoxShadow defaultShadow(
    {double blurRadius = 5, Offset offset = const Offset(2, 2)}) {
  return BoxShadow(
    color: Colors.black45,
    blurRadius: blurRadius,
    offset: offset,
  );
}

TextStyle titleStyle = const TextStyle(
  fontSize: 48,
  fontWeight: FontWeight.bold,
  color: Colors.white,
  shadows: [
    Shadow(blurRadius: 10.0, color: Colors.black45, offset: Offset(2.0, 2.0)),
  ],
);

TextStyle subtitleStyle = const TextStyle(fontSize: 20, color: Colors.white70);

ButtonStyle menuButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: Colors.white,
  foregroundColor: Colors.blue.shade900,
  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  elevation: 5,
);