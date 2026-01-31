import 'package:flutter/material.dart';

class UrgencyChip extends StatelessWidget {
  final int urgency;

  const UrgencyChip(this.urgency, {super.key});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('Urgency $urgency/5'),
      backgroundColor: Colors.red.shade100,
      labelStyle: const TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
