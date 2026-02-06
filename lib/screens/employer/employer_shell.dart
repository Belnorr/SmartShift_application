import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class EmployerShell extends StatefulWidget {
  final Widget child;
  const EmployerShell({super.key, required this.child});

  @override
  State<EmployerShell> createState() => _EmployerShellState();
}

class _EmployerShellState extends State<EmployerShell> {
  int _indexFromPath(String path) {
    if (path.startsWith('/e/dashboard')) return 0;
    if (path.startsWith('/e/create')) return 1;
    if (path.startsWith('/e/manage')) return 2;
    return 0;
  }

  void _goToCreateWithFrom(String fromPath) {
    final from = Uri.encodeComponent(fromPath);
    context.go('/e/create?from=$from');
  }

  void _go(int idx, String currentPath) {
    switch (idx) {
      case 0:
        context.go('/e/dashboard');
        break;
      case 1:
        _goToCreateWithFrom(currentPath);
        break;
      case 2:
        context.go('/e/manage');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ss = context.ss;
    final state = GoRouterState.of(context);
    final path = state.uri.path;
    final idx = _indexFromPath(path);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _PillBottomNav(
            index: idx,
            onTap: (i) => _go(i, path),
            surface: ss.surface,
            text: ss.text,
            muted: ss.muted,
            primary: ss.primary,
          ),
        ),
      ),
    );
  }
}

class _PillBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  final Color surface;
  final Color text;
  final Color muted;
  final Color primary;

  const _PillBottomNav({
    required this.index,
    required this.onTap,
    required this.surface,
    required this.text,
    required this.muted,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    const track = Color(0xFFE5E7EB);

    Widget tab({
      required String label,
      required bool selected,
      required VoidCallback onPressed,
    }) {
      return Expanded(
        child: GestureDetector(
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            height: 44,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: selected ? text : muted,
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget plusButton(
        {required bool selected, required VoidCallback onPressed}) {
      return GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE7E5EE)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.add,
            size: 22,
            color: selected ? primary : text,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7E5EE)),
      ),
      child: Row(
        children: [
          tab(
            label: "DashBoard",
            selected: index == 0,
            onPressed: () => onTap(0),
          ),
          const SizedBox(width: 8),
          plusButton(
            selected: index == 1,
            onPressed: () => onTap(1),
          ),
          const SizedBox(width: 8),
          tab(
            label: "Manage",
            selected: index == 2,
            onPressed: () => onTap(2),
          ),
        ],
      ),
    );
  }
}
