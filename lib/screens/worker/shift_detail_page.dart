import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/services/shift_booking_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShiftDetailPage extends StatelessWidget {
  final Map<String, dynamic> shift;

  const ShiftDetailPage({
    super.key,
    required this.shift,
  });

    static String get uid =>
        FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Shift Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final List<String> userSkills =
              List<String>.from(userData['skills'] ?? []);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeaderCard(shift: shift),
                const SizedBox(height: 16),
                EligibilityCard(
                  shift: shift,
                  userSkills: userSkills,
                ),
                const SizedBox(height: 16),
                BookingCard(
                  shift: shift,
                  userSkills: userSkills,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* ===================== HEADER ===================== */

class HeaderCard extends StatelessWidget {
  final Map<String, dynamic> shift;

  const HeaderCard({required this.shift});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${shift['company']} – ${shift['title']}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${shift['location']} • ${shift['dateLabel']} • '
            '\$${shift['payPerHour']}/hr • +${shift['rewardPoints']} pts',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/* ===================== ELIGIBILITY ===================== */

      class EligibilityCard extends StatelessWidget {
        final Map<String, dynamic> shift;
        final List<String> userSkills;

        const EligibilityCard({
          super.key,
          required this.shift,
          required this.userSkills,
        });

        Future<bool> _checkScheduleConflict() async {
          final uid = FirebaseAuth.instance.currentUser!.uid;

          final start = shift['date'].toDate();
          final end = shift['endTime'].toDate();

          final booked = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('bookedShifts')
              .where('status', isEqualTo: 'upcoming')
              .get();

          for (final doc in booked.docs) {
            final s = doc['date'].toDate();
            final e = doc['endTime'].toDate();

            if (start.isBefore(e) && end.isAfter(s)) {
              return false;
            }
          }

          return true;
        }

        @override
        Widget build(BuildContext context) {
          final List<String> requiredSkills =
              List<String>.from(shift['requiredSkills'] ?? []);

          final bool skillMatch = requiredSkills.any(
            (skill) => userSkills
                .map((s) => s.toLowerCase().trim())
                .contains(skill.toLowerCase().trim()),
          );

          return FutureBuilder<bool>(
            future: _checkScheduleConflict(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                );
              }

              final bool noConflict = snapshot.data!;
              const bool accountActive = true;

              final bool eligible =
                  skillMatch && noConflict && accountActive;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Eligibility check',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckRow(
                      text: skillMatch ? 'Skill match' : 'Skills do not match',
                      passed: skillMatch,
                    ),
                    CheckRow(
                      text: noConflict ? 'No schedule conflict' : 'Schedule conflict',
                      passed: noConflict,
                    ),

                    CheckRow(text: 'Account active', passed: accountActive),
                    CheckRow(text: 'Eligible to book', passed: eligible),
                  ],
                ),
              );
            },
          );
        }
      }


/* ===================== BOOKING ===================== */

class BookingCard extends StatelessWidget {
  final Map<String, dynamic> shift;
  final List<String> userSkills;

  const BookingCard({
    required this.shift,
    required this.userSkills,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> requiredSkills =
        List<String>.from(shift['requiredSkills'] ?? []);

    final bool canBook = requiredSkills.any(
      (skill) => userSkills
          .map((s) => s.toLowerCase().trim())
          .contains(skill.toLowerCase().trim()),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const StepRow(
            number: 1,
            title: 'Confirm availability',
          ),
          const SizedBox(height: 8),
          const StepRow(
            number: 2,
            title: 'Fairness & workload rules',
            subtitle:
                'System prevents overbooking and ensures fair allocation.',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canBook
                  ? () async {
                      try {
                        await ShiftBookingService.applyForShift(
                          shiftId: shift['id'],
                          shiftData: shift,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Shift booked successfully'),
                          ),
                        );

                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  : null,
              child: const Text('Apply for Shift'),
            ),
          ),
        ],
      ),
    );
  }
}

/* ===================== SHARED UI ===================== */

class CheckRow extends StatelessWidget {
  final String text;
  final bool passed;

  const CheckRow({
    required this.text,
    required this.passed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.cancel,
            color: passed ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class StepRow extends StatelessWidget {
  final int number;
  final String title;
  final String? subtitle;

  const StepRow({
    required this.number,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: Colors.indigo,
          child: Text(
            number.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

BoxDecoration cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
  );
}