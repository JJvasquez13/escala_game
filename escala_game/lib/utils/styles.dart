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