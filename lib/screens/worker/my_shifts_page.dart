import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/shift_manage_service.dart';

class MyShiftsPage extends StatefulWidget {
  const MyShiftsPage({super.key});

  @override
  State<MyShiftsPage> createState() => _MyShiftsPageState();
}

class _MyShiftsPageState extends State<MyShiftsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late final String uid;


      @override
      void initState() {
        super.initState();
        _tabController = TabController(length: 3, vsync: this);
        uid = FirebaseAuth.instance.currentUser!.uid;
      }


  Stream<QuerySnapshot> _getShifts(String status) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('bookedShifts')
        .where('status', isEqualTo: status)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'My Shifts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2437), // dark background
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              indicatorPadding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 6,
              ),


                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: const Color(0xFF1F2437),
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Manage'),
                ],
              ),
            ),
          ),
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          ShiftList(stream: _getShifts('upcoming')),
          ShiftList(stream: _getShifts('completed')),
          ShiftList(
            stream: _getShifts('upcoming'),
            isManage: true,
            userId: uid,
          ),
        ],
      ),
    );
  }
}

class ShiftList extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final bool isManage;
  final String? userId;

  const ShiftList({
    super.key,
    required this.stream,
    this.isManage = false,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading shifts'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text('No shifts found'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final Timestamp? startTs = data['date'];
            final Timestamp? endTs = data['endTime'];

            final timeLabel = (startTs != null && endTs != null)
                ? '${DateFormat('EEE, d MMM').format(startTs.toDate())} '
                    '${DateFormat('HH:mm').format(startTs.toDate())}'
                    ' - ${DateFormat('HH:mm').format(endTs.toDate())}'
                : '';

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title'],
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['company'],
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${data['payPerHour']}/h',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data['location'],
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const Icon(Icons.access_time,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        timeLabel,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _pill(
                        'Urgency ${data['urgency']}/5',
                        Colors.orange,
                      ),
                      _pill(
                        '+${data['rewardPoints']} pts',
                        Colors.blue,
                      ),
                      ...List<String>.from(
                        data['requiredSkills'] ?? [],
                      ).map(
                        (s) => _pill(s, Colors.grey),
                      ),
                    ],
                  ),

                  if (isManage) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Cancel shift?'),
                              content: const Text(
                                'Cancelling will deduct 50 points and increase late cancellations.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('No'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('Yes, cancel'),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) return;

                          await ShiftManageService.cancelShift(
                            userId: userId!,
                            shiftId: doc.id,
                          );
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color),
      ),
    );
  }
}
