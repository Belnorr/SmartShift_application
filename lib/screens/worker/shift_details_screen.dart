import 'package:flutter/material.dart';

class ShiftDetailsScreen extends StatelessWidget {
  const ShiftDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shift Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Cafe Assistant", style: TextStyle(fontSize: 22)),
            const SizedBox(height: 10),
            const Text("\$12 / hour"),
            const SizedBox(height: 20),
            FilledButton(onPressed: () {}, child: const Text("Book Shift")),
          ],
        ),
      ),
    );
  }
}
