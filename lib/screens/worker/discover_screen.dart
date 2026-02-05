import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../core/models/shift.dart';
import '../../widgets/shift_card.dart';

class DiscoverShiftsScreen extends StatelessWidget {
  const DiscoverShiftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService.instance;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Discover Shifts',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by role or location',
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Shift>>(
              stream: db.getAllShifts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final shifts = snapshot.data!;
                if (shifts.isEmpty) {
                  return const Center(child: Text('No shifts available'));
                }

                return ListView(
                  children: shifts
                      .map((s) => ShiftCard(shift: s))
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
