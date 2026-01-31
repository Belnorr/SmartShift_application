import 'package:flutter/material.dart';

import 'discover_page.dart';
import 'my_shifts_page.dart';
import 'rewards_page.dart';
import 'profile_page.dart';

class WorkerShell extends StatefulWidget {
  const WorkerShell({super.key});

  @override
  State<WorkerShell> createState() => _WorkerShellState();
}

class _WorkerShellState extends State<WorkerShell> {
  int _index = 0;

  final List<Widget> _pages = const [
    DiscoverPage(),
    MyShiftsPage(),
    RewardsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Stack(
        children: [
          // Page content (leave space for floating bar)
          Padding(
            padding: const EdgeInsets.only(bottom: 96),
            child: _pages[_index],
          ),

          // Floating bottom navigation
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _FloatingSegmentedBar(
              index: _index,
              onChanged: (i) {
                setState(() {
                  _index = i;
                });
              },
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
            // Sliding white background
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
                          color:
                              selected ? Colors.black : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _items[i]['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected
                                ? Colors.black
                                : Colors.grey,
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
