import 'package:flutter/material.dart';

class PointsChip extends StatelessWidget {
  final int points;

  const PointsChip(this.points, {super.key});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('+$points pts'),
      backgroundColor: Colors.blue.shade100,
      labelStyle: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
