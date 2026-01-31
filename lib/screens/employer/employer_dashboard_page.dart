import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmployerDashboardPage extends StatelessWidget {
  const EmployerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employer Dashboard'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('shifts')
            .where('employerId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final shifts = snap.data!.docs;
          final totalShifts = shifts.length;
          final activeShifts =
              shifts.where((s) => s['status'] == 'open').length;

          int totalBookings = 0;
          for (final s in shifts) {
            totalBookings += (s['bookedCount'] ?? 0) as int;
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    _statCard(
                      title: 'Total Shifts',
                      value: totalShifts.toString(),
                      icon: Icons.work_outline,
                    ),
                    const SizedBox(width: 16),
                    _statCard(
                      title: 'Active Shifts',
                      value: activeShifts.toString(),
                      icon: Icons.play_circle_outline,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _statCard(
                      title: 'Total Bookings',
                      value: totalBookings.toString(),
                      icon: Icons.people_outline,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
