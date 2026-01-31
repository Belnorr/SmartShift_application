import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageShiftsPage extends StatelessWidget {
  const ManageShiftsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Shifts'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('shifts')
            .where('employerId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.data!.docs.isEmpty) {
            return const Center(child: Text('No shifts created'));
          }

          final shifts = snap.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: shifts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final doc = shifts[i];
              final d = doc.data();

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        '${d['company']} • ${d['location']}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Slots: ${d['bookedCount']}/${d['capacity']}',
                          ),
                          Chip(
                            label: Text(d['status']),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _showBookings(
                                  context,
                                  doc.id,
                                );
                              },
                              child: const Text('View Bookings'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: d['status'] == 'open'
                                  ? () => _closeShift(doc.id)
                                  : null,
                              child: const Text('Close Shift'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _closeShift(String shiftId) async {
    await FirebaseFirestore.instance
        .collection('shifts')
        .doc(shiftId)
        .update({'status': 'closed'});
  }

  void _showBookings(BuildContext context, String shiftId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Bookings'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('shifts')
                .doc(shiftId)
                .collection('bookings')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snap.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No bookings yet'),
                );
              }

              return ListView.builder(
                itemCount: snap.data!.docs.length,
                itemBuilder: (context, i) {
                  final d = snap.data!.docs[i].data();
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(d['workerId']),
                    subtitle: Text('Status: ${d['status']}'),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
