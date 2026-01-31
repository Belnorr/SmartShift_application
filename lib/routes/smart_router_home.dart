import 'package:flutter/material.dart';

import '../screens/worker/worker_shell.dart';
import '../screens/employer/employer_shell.dart';

class SmartRouterHome extends StatelessWidget {
  final String role;

  const SmartRouterHome({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    if (role == 'employer') {
      return const EmployerShell();
    }

    // default = employee
    return const WorkerShell();
  }
}
