import 'package:flutter/material.dart';

import 'employer_dashboard_page.dart';
import 'create_shift_page.dart';
import 'manage_shifts_page.dart';

class EmployerShell extends StatefulWidget {
  const EmployerShell({super.key});

  @override
  State<EmployerShell> createState() => _EmployerShellState();
}

class _EmployerShellState extends State<EmployerShell> {
  int _index = 0;

  final _pages = const [
    EmployerDashboardPage(),
    CreateShiftPage(),
    ManageShiftsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Manage',
          ),
        ],
      ),
    );
  }
}
