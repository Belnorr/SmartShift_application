import 'package:flutter/material.dart';

class TagChip extends StatelessWidget {
  final String text;

  const TagChip(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text),
      backgroundColor: Colors.grey.shade200,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
