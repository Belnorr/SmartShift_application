import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShiftBookingService {
  static Future<void> applyForShift({
    required String shiftId,
    required Map<String, dynamic> shiftData,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final bookedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('bookedShifts')
        .doc(shiftId);

    final existing = await bookedRef.get();
    if (existing.exists) {
      throw Exception('Shift already booked');
    }

    // MUST be a Timestamp from your shift doc
    final Timestamp startTs = shiftData['date'] as Timestamp;

    // Rebuild endTime to be same day as start, using endHour/endMinute if you have it.
    // If shiftData already has a proper Timestamp endTime, use it.
    Timestamp endTs;
    final rawEnd = shiftData['endTime'];

    if (rawEnd is Timestamp) {
      endTs = rawEnd;
    } else {
      // fallback: compute from dateLabel day + endHour/endMinute
      // You NEED endHour/endMinute in shiftData for this branch.
      final endHour = shiftData['endHour'] as int;
      final endMinute = shiftData['endMinute'] as int;

      final start = startTs.toDate();
      final end = DateTime(start.year, start.month, start.day, endHour, endMinute);

      endTs = Timestamp.fromDate(end);
    }

    await bookedRef.set({
      'shiftId': shiftId,
      'title': shiftData['title'],
      'company': shiftData['company'],
      'location': shiftData['location'],
      'payPerHour': shiftData['payPerHour'],
      'rewardPoints': shiftData['rewardPoints'],
      'urgency': shiftData['urgency'],
      'date': startTs,
      'endTime': endTs,
      'status': 'upcoming',
      'rewardAwarded': false,
      'bookedAt': FieldValue.serverTimestamp(),
    });
  }
}
