import 'package:go_router/go_router.dart';

import '../screens/role_gate.dart';
import '../core/models/shift.dart';

import '../screens/employer/employer_shell.dart';
import '../screens/employer/dashboard_screen.dart';
import '../screens/employer/create_shift_screen.dart';
import '../screens/employer/manage_shifts_screen.dart';
import '../screens/employer/edit_shift_screen.dart';

final GoRouter appRouter = GoRouter(
  // ✅ start at "/" so RoleGate decides where to go
  initialLocation: '/',
  routes: [
    // ✅ RoleGate is the entry point (login -> role -> correct screens)
    GoRoute(
      path: '/',
      builder: (context, state) => const RoleGate(),
    ),

    // ✅ Employer area (bottom nav shell)
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

    // ✅ Employer edit screen (outside shell so no bottom nav)
    GoRoute(
      path: '/e/edit',
      builder: (context, state) {
        final shift = state.extra as Shift;
        return EmployerEditShiftScreen(shift: shift);
      },
    ),
  ],
);
