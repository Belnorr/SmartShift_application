import 'package:flutter/material.dart';

import '../screens/worker/discover_screen.dart';
import '../screens/employer/dashboard_screen.dart';

class SmartRouterHome extends StatelessWidget {
  final String role;

  const SmartRouterHome({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    if (role == 'employer') {
      return const EmployerDashboardScreen(); 
    }
    return const DiscoverPage(); 
  }
}
