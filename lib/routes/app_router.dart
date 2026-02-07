import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/models/shift.dart';
import '../routes/root_gate.dart';

// employer imports
import '../screens/employer/employer_shell.dart';
import '../screens/employer/dashboard_screen.dart';
import '../screens/employer/create_shift_screen.dart';
import '../screens/employer/manage_shifts_screen.dart';
import '../screens/employer/edit_shift_screen.dart';

// worker imports
import '../screens/worker/worker_shell.dart';
import '../screens/worker/discover_screen.dart';
import '../screens/worker/my_shifts_screen.dart';
import '../screens/worker/profile_screen.dart';
import '../screens/worker/rewards_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const RootGate(),
    ),

    GoRoute(
      path: '/w/home',
      redirect: (_, __) => '/w/discover',
    ),

    // Employer shell (bottom nav shell)
    ShellRoute(
      builder: (context, state, child) => EmployerShell(child: child),
      routes: [
        GoRoute(
          path: '/e/dashboard',
          builder: (context, state) => const EmployerDashboardScreen(),
        ),
        GoRoute(
          path: '/e/create',
          builder: (context, state) => const CreateShiftScreen(),
        ),
        GoRoute(
          path: '/e/manage',
          builder: (context, state) => const EmployerManageShiftsScreen(),
        ),
      ],
    ),

    // Employer edit screen 
    GoRoute(
      path: '/e/edit',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is! Shift) {
          return const Scaffold(
            body: Center(child: Text("No shift data passed")),
          );
        }
        return EmployerEditShiftScreen(shift: extra);
      },
    ),

    // Worker shell (bottom nav shell)
    ShellRoute(
      builder: (context, state, child) => WorkerShell(child: child),
      routes: [
        GoRoute(
          path: '/w/discover',
          builder: (context, state) => const DiscoverPage(),
        ),
        GoRoute(
          path: '/w/myshifts',
          builder: (context, state) => const MyShiftsPage(),
        ),
        GoRoute(
          path: '/w/rewards',
          builder: (context, state) => const RewardsPage(),
        ),
        GoRoute(
          path: '/w/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),
  ],
);
