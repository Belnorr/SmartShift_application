import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WorkerShell extends StatefulWidget {
  final Widget child;
  const WorkerShell({super.key, required this.child});

  @override
  State<WorkerShell> createState() => _WorkerShellState();
}

class _WorkerShellState extends State<WorkerShell> {
  int _indexFromPath(String path) {
    if (path.startsWith('/w/discover')) return 0;
    if (path.startsWith('/w/myshifts')) return 1;
    if (path.startsWith('/w/rewards')) return 2;
    if (path.startsWith('/w/profile')) return 3;
    return 0;
  }

  void _go(int i) {
    switch (i) {
      case 0:
        context.go('/w/discover');
        break;
      case 1:
        context.go('/w/myshifts');
        break;
      case 2:
        context.go('/w/rewards');
        break;
      case 3:
        context.go('/w/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final idx = _indexFromPath(path);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 96),
            child: widget.child, 
          ),

          // Floating bottom navigation
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _FloatingSegmentedBar(
              index: idx,
              onChanged: _go,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingSegmentedBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _FloatingSegmentedBar({
    required this.index,
    required this.onChanged,
  });

  static const _items = [
    {'label': 'Discover', 'icon': Icons.search},
    {'label': 'My Shifts', 'icon': Icons.work_outline},
    {'label': 'Rewards', 'icon': Icons.card_giftcard},
    {'label': 'Profile', 'icon': Icons.person_outline},
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(32),
      color: Colors.transparent,
      child: Container(
        height: 64,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              alignment: Alignment(
                -1 + (index * 2 / (_items.length - 1)),
                0,
              ),
              child: Container(
                width: (width - 32 - 12) / _items.length,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),

            // Tabs
            Row(
              children: List.generate(_items.length, (i) {
                final selected = i == index;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _items[i]['icon'] as IconData,
                          size: 22,
                          color: selected ? Colors.black : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _items[i]['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? Colors.black : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
