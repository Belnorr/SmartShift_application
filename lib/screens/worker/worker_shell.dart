import 'package:flutter/material.dart';
import 'discover_screen.dart';
import 'my_shifts_screen.dart';
import 'rewards_screen.dart';
import 'profile_screen.dart';

class WorkerShell extends StatefulWidget {
  const WorkerShell({super.key});

  @override
  State<WorkerShell> createState() => _WorkerShellState();
}

class _WorkerShellState extends State<WorkerShell> {
  int index = 0;

  final pages = const [
    DiscoverShiftsScreen(),
    MyShiftsScreen(),
    RewardsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'My Shifts'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Rewards'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
