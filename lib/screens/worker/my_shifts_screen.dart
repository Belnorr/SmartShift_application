import 'package:flutter/material.dart';

class MyShiftsScreen extends StatelessWidget {
  const MyShiftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Shifts")),
      body: ListView(
        children: const [
          ListTile(title: Text("Cafe Assistant"), subtitle: Text("Upcoming")),
        ],
      ),
    );
  }
}
